---
title: "Why My Git Server 502'd: A Journey Through Kubernetes Disk Pressure"
date: 2024-11-10T01:35:00Z
draft: false
tags: ["Kubernetes", "Homelab", "DevOps", "Linux", "Networking"]
---

I went to push some changes to my self-hosted Git server tonight, and was greeted by a familiar, sinking HTTP status:

```bash
fatal: unable to access 'https://git.divyam.dev/divyam/divyam.dev/': The requested URL returned error: 502
```

502 Bad Gateway.

My homelab setup runs on a Raspberry Pi 5 cluster with Caddy acting as a reverse proxy in front of services hosted in Kubernetes (k3s). Whenever Caddy spits back a 502, it means Caddy itself is alive and well, but whatever upstream service it's trying to reach is either completely dead or refusing connections.

What started as a quick "let me check why the container died" turned into a neat tour of how Kubelet protects nodes from catastrophic disk failures.

---

## Down the Rabbit Hole

First, I checked if the Git namespace was even up:

```bash
kubectl get pod -n forgejo
```

The output was not encouraging:

```
NAME                      READY   STATUS                   RESTARTS      AGE
forgejo-9f576bf5f-5pcpq   0/1     Pending                  0             10d
forgejo-9f576bf5f-dqp8l   0/1     ContainerStatusUnknown   7 (43d ago)   187d
forgejo-9f576bf5f-rtddd   0/1     Completed                0             37d
```

Not a single pod was running. Even worse, the newest replacement pod had been sitting in `Pending` for **ten days**.

A pod stuck in `Pending` means the Kubernetes scheduler hasn't assigned it to a node. To find out why, `kubectl describe` is always the first move:

```bash
kubectl describe pod forgejo-9f576bf5f-5pcpq -n forgejo
```

Down in the `Events` section:

```
Warning  FailedScheduling  default-scheduler
0/1 nodes are available: 1 node(s) had untolerated taint(s).
```

In Kubernetes, a **taint** allows a node to repel a set of pods. Unless a pod explicitly has a matching *toleration* in its spec, the scheduler refuses to put it there. On a multi-node cluster, the scheduler would simply place the pod on another healthy worker node. But on a single-node homelab machine, if your only node is tainted, everything grinds to a halt.

---

## Inspecting the Taint

To see what taint was placed on the node:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

Output:

```
NAME   TAINTS
reze   [map[effect:NoSchedule key:node.kubernetes.io/disk-pressure timeAdded:2026-10-30T18:21:12Z]]
```

`node.kubernetes.io/disk-pressure`. And look at the timestamp: added on October 30th, exactly 10 days ago when the pod went pending.

---

## The Kubelet Eviction Threshold

Kubelet constantly monitors node resources (disk, memory, PID exhaustion). By default, if the root filesystem drops below a specific free-space threshold (typically 10% to 15% available space), Kubelet steps in:

1. It immediately marks the node with a `disk-pressure:NoSchedule` taint so no new workloads land on the starving drive.
2. It starts evicting pods that exceed their local storage limits or don't have guaranteed QoS to prevent the node from kernel-panicking or corrupting its filesystem.

Checking the disk on the Pi:

```bash
df -h /
```

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p2  117G  106G  6.7G  95% /
```

**95% full.** With only 6.7GB of free headroom on a 120GB drive, Kubelet had slammed the brakes to protect the system.

Between accumulated container layers in `/var/lib/containerd`, stale systemd journal logs, and miscellaneous large files that had piled up in user directories over months of uptime, the drive was completely starved.

---

## Clearing the Pressure

Recovering from disk pressure requires getting disk usage safely below Kubelet's eviction threshold. Once the available space rises back above the recovery margin, Kubelet automatically removes the taint without needing a node reboot.

A few quick cleanup steps reclaimed immediate space:

### 1. Pruning stale container images
Container runtimes tend to hoard old image layers from previous deployments:

```bash
sudo crictl rmi --prune
```

On a small node that's pulled multiple versions of apps, this can easily reclaim 10 to 20 GB.

### 2. Trimming systemd journal logs
If your services are chatty, systemd journals can quietly eat gigabytes of storage over a few months:

```bash
sudo journalctl --vacuum-size=100M
```

### 3. Evicting dead pods
Cleaning up orphaned pods in `Unknown` status allows Kubernetes to cleanly release their volume claim locks:

```bash
kubectl delete pod <old-pod-name> -n forgejo --force --grace-period=0
```

### 4. Clearing large local files
Finding and removing bulky, forgotten downloads and old archive dumps across the filesystem brought usage down well under 80%.

---

## The Recovery

Within roughly 60 seconds of the disk usage dropping below the threshold, Kubelet noticed the recovery:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

```
NAME   TAINTS
reze   <none>
```

The taint vanished. The Kubernetes scheduler immediately woke up, evaluated the pending Forgejo pod, found an available node, and transitioned it:

```
Pending -> ContainerCreating -> Running (1/1)
```

Caddy detected the upstream backend was healthy again, 502s disappeared, and `git push` succeeded on the first try.

---

## What I Liked About This

A lot of people complain about Kubernetes being "overcomplicated for a homelab." And sure, if you just want to run a script, it's overkill.

But situations like this are a great reminder of why these mechanisms exist in the first place. Kubelet didn't crash, the Pi didn't lock up with a read-only filesystem, and SQLite didn't corrupt its database mid-write. The node saw danger, cordoned itself off gracefully, waited for human intervention to fix the underlying physical storage, and recovered autonomously the moment space was freed.

Understanding the layers—from reverse proxy down through the container scheduler to local inode usage—turns a mysterious 502 into a logical, predictable sequence of dominoes to follow.


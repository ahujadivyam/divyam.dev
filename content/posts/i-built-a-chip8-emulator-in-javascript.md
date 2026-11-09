---
title: "I Built a CHIP-8 Emulator in JavaScript"
date: 2021-08-20T10:00:00Z
draft: false
tags: ["JavaScript", "Emulators", "Canvas", "WebAudio"]
---

If you've ever wanted to understand how computers actually work — not the "how to center a div" kind, but the "how does a CPU fetch and execute instructions" kind — building an emulator is one of the best ways to do it.

A while back I built a [CHIP-8 emulator](https://github.com/ahujadivyam/chip_eight.js) in vanilla JavaScript. No frameworks, no build tools, no npm install. Just the browser's Canvas API, Web Audio API, and a few hundred lines of code pretending to be a computer from 1977.

## What's a CHIP-8?

CHIP-8 is an interpreted programming language from the mid-1970s, originally designed for hobbyist microcomputers like the COSMAC VIP. It's not a real CPU — it's more like a virtual machine spec. But it has all the things that make a real system interesting: memory, registers, a stack, timers, input, graphics, and sound.

It's also the "hello world" of emulator development. The instruction set is small (35 opcodes), the display is tiny (64×32 pixels), and there's a massive community of ROMs and documentation. If you can emulate CHIP-8, you'll have the foundation to tackle Game Boy, NES, or anything else.

## The Architecture

Here's what you're emulating:

- **4KB of RAM** — that's it. The entire address space is `0x000` to `0xFFF`.
- **16 general-purpose 8-bit registers** (V0–VF). VF doubles as a flag register.
- **A 16-bit index register (I)** for pointing at memory locations.
- **A program counter (PC)** that starts at `0x200` — because the first 512 bytes are reserved for the interpreter itself (and the built-in font sprites).
- **A stack** for subroutine return addresses (16 levels deep).
- **Two timers** — a delay timer and a sound timer, both counting down at 60Hz.
- **A 16-key hex keypad** for input.
- **A 64×32 monochrome display** where pixels are either on or off.

I modeled each of these as a separate JavaScript class: `CPU`, `Renderer`, `Keyboard`, and `Speaker`. Clean separation of concerns, and it makes the code easy to reason about.

## The Core Loop

The CPU instruction cycle is straightforward: every tick, you fetch, decode, and execute.

Because CHIP-8 opcodes are two bytes long (big-endian), fetching means grabbing two consecutive bytes from memory at the current program counter and combining them into a 16-bit number:

```javascript
let opcode = (this.memory[this.pc] << 8) | this.memory[this.pc + 1];
this.pc += 2;
```

Decoding is just bit-masking. The highest 4 bits tell you the instruction category, and the remaining 12 bits hold register indices or memory offsets:

```javascript
let x   = (opcode & 0x0F00) >> 8;   // register index
let y   = (opcode & 0x00F0) >> 4;   // register index
let nn  = opcode & 0x00FF;           // 8-bit constant
let nnn = opcode & 0x0FFF;           // 12-bit address
```

Execution is a switch statement. `6XNN` sets register `Vx = nn`. `1NNN` sets `PC = nnn`. `DXYN` draws a sprite. If the sound timer is greater than zero, you buzz the speaker. That's essentially it.

## Drawing Sprites

The most interesting opcode is `DXYN` — the draw instruction. CHIP-8 graphics are XOR-based. You don't "set" pixels, you *toggle* them.

Each sprite is 8 pixels wide and N pixels tall. The sprite data lives in memory at whatever address the I register points to. Each byte represents one row of 8 pixels, where each bit is a pixel:

```javascript
for (let row = 0; row < height; row++) {
    let spriteByte = this.memory[this.I + row];
    for (let col = 0; col < 8; col++) {
        if (spriteByte & (0x80 >> col)) {
            let px = (x + col) % 64;
            let py = (y + row) % 32;
            // Toggle pixel — if it was ON and gets turned OFF, set VF = 1
            if (this.display[py * 64 + px]) {
                this.registers[0xF] = 1;  // collision!
            }
            this.display[py * 64 + px] ^= 1;
        }
    }
}
```

That VF collision flag is how games detect when things hit each other. Pong uses it to know when the ball hits a paddle. It's elegant — one bit of state doing the job of a physics engine.

The display buffer is a flat array of 2048 values (64 × 32). Each frame, I iterate over it and draw scaled-up rectangles on an HTML5 Canvas:

```javascript
render() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    for (let i = 0; i < this.display.length; i++) {
        if (this.display[i]) {
            let x = (i % 64) * this.scale;
            let y = Math.floor(i / 64) * this.scale;
            this.ctx.fillRect(x, y, this.scale, this.scale);
        }
    }
}
```

At 10× scale, you get a nice chunky 640×320 canvas that looks properly retro.

## The Keyboard Problem

CHIP-8 has a 16-key hex keypad (0–F). Obviously we don't have one of those lying around, so I mapped it to a 4×4 grid on a QWERTY keyboard:

```
CHIP-8 Keypad        Keyboard
┌───┬───┬───┬───┐    ┌───┬───┬───┬───┐
│ 1 │ 2 │ 3 │ C │    │ 1 │ 2 │ 3 │ 4 │
├───┼───┼───┼───┤    ├───┼───┼───┼───┤
│ 4 │ 5 │ 6 │ D │    │ Q │ W │ E │ R │
├───┼───┼───┼───┤    ├───┼───┼───┼───┤
│ 7 │ 8 │ 9 │ E │    │ A │ S │ D │ F │
├───┼───┼───┼───┤    ├───┼───┼───┼───┤
│ A │ 0 │ B │ F │    │ Z │ X │ C │ V │
└───┴───┴───┴───┘    └───┴───┴───┴───┘
```

One interesting edge case: the `FX0A` instruction. It's a *blocking* key wait — the CPU literally halts until the user presses a key. In a real system that's just a busy loop. In JavaScript, you can't block the main thread (and you shouldn't), so I used a callback pattern. When the CPU hits `FX0A`, it registers an `onNextKeyPress` callback and stops cycling. When a keydown event fires, the callback resolves, stores the key in the target register, and the CPU resumes.

## Sound

CHIP-8 sound is delightfully simple. There's one sound: a buzzer. It plays when the sound timer is greater than zero.

I used the Web Audio API to create a square wave oscillator at 440Hz — a nice harsh beep that feels appropriately retro. The only tricky part is dealing with browser autoplay policies: you can't start an `AudioContext` without user interaction, so the first keypress initializes the audio.

## The Game Loop

Everything comes together in a `requestAnimationFrame` loop:

```javascript
function step() {
    for (let i = 0; i < 10; i++) {
        cpu.cycle();
    }
    renderer.render();
    requestAnimationFrame(step);
}
```

Running ~10 CPU cycles per frame at 60fps gives you roughly 600 instructions per second, which is in the ballpark of original CHIP-8 speed. ROMs load via the Fetch API as `ArrayBuffer`, get written into memory starting at `0x200`, and away you go.

Pong, Space Invaders, Tetris, Breakout — they all just work.

## Why Build This

I won't pretend this is useful software. Nobody needs another CHIP-8 emulator. But that's not the point.

The point is that after building this, I understood things I'd only read about before: how program counters work, why instructions are fixed-width, how XOR collision detection works, what "memory-mapped I/O" actually means in practice. You read about fetch-decode-execute in a textbook and it's abstract. You implement it and it clicks.

If you're into systems programming and want a weekend project that'll teach you more about machine architecture than a month of tutorials, build one yourself. Cowgod's [CHIP-8 technical reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM) is the canonical spec and has everything you need.

The full code is on GitHub: [github.com/ahujadivyam/chip_eight.js](https://github.com/ahujadivyam/chip_eight.js)


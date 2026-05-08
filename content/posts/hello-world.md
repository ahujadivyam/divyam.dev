---
title: "Hello World"
date: 2026-05-08
description: "First post on my new blog, built with Hugo."
tags: ["meta", "hugo"]
---

Welcome to my new blog! I've rebuilt my personal website from scratch using [Hugo](https://gohugo.io/), a fast static site generator written in Go.

## Why Hugo?

I wanted something minimal, fast, and that gets out of the way. Hugo checks all the boxes:

- **Blazing fast builds** — the entire site builds in under 100ms
- **Markdown-first** — I write posts in plain markdown files
- **Zero JavaScript** — the site ships pure HTML and CSS
- **Built-in features** — syntax highlighting, RSS feeds, sitemaps, all out of the box

## The Design

The design is inspired by the [Cactus Dark](https://probberechts.github.io/hexo-theme-cactus/) theme — a minimalist, terminal-inspired aesthetic with monospace typography and a dark color scheme. I built the theme from scratch for full control.

Here's a quick code example to make sure syntax highlighting works:

```python
def greet(name: str) -> str:
    """Return a greeting message."""
    return f"Hello, {name}! Welcome to divyam.dev"

if __name__ == "__main__":
    print(greet("World"))
```

And some JavaScript too:

```javascript
const fetchPosts = async () => {
  const response = await fetch('/api/posts');
  const posts = await response.json();
  return posts.filter(post => post.published);
};
```

## What's Next?

I plan to write about:

- Full-stack development patterns and best practices
- Side projects and what I learn building them
- Deep dives into interesting technical problems
- Tools and workflows that make development better

Stay tuned — there's more coming soon.

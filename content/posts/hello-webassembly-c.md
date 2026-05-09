---
title: "Hello WebAssembly: Getting Started with C/C++"
date: 2023-11-21T06:40:48Z
draft: false
tags: ["WebAssembly", "C", "C++", "Emscripten"]
---

If you've spent any time working on performance-critical web applications, you've probably hit the performance ceiling of JavaScript. I ran into this heavily during my Google Summer of Code project working on Chromium's audio processing pipeline. We needed near-native speeds to process audio without stuttering, and standard JavaScript just wasn't going to cut it.

Enter **WebAssembly** (Wasm). 

WebAssembly is essentially a low-level binary format that runs directly in the browser at near-native speeds. It lets us write code in systems languages like C, C++, or Rust, compile it, and run it right alongside our JavaScript. 

Today, I want to walk you through the absolute basics: taking a simple C program and running it in your browser. 

## The Magic Tool: Emscripten

To bridge the gap between C/C++ and the web, we need a toolchain. The undisputed heavyweight champion here is **Emscripten**. It takes your C/C++ code, compiles it into a `.wasm` binary, and even generates the JavaScript "glue" code needed to load it into the browser.

Let's get it installed. Open your terminal and run:

```bash
# Clone the Emscripten SDK
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk

# Fetch and install the latest tools
./emsdk install latest

# Make them active
./emsdk activate latest

# Load the environment variables (you'll need to do this for new terminal sessions)
source ./emsdk_env.sh
```

## Writing some C Code

Let's not overcomplicate things for our first run. Create a file called `hello.c`:

```c
#include <stdio.h>

int main() {
    printf("Hello, WebAssembly!\n");
    return 0;
}
```

It doesn't get much simpler than that. But how do we get this to run in Chrome or Firefox?

## Compiling to Wasm

With our Emscripten environment active, we can use `emcc` (the Emscripten Compiler Frontend). In the same directory as your `hello.c` file, run:

```bash
emcc hello.c -o hello.html
```

Here is what's happening under the hood:
- `emcc` is our compiler.
- `-o hello.html` tells Emscripten that we don't just want the raw binary; we want an HTML file we can actually open. 

If you look at your directory now, Emscripten generated three files: `hello.wasm` (the actual compiled binary), `hello.js` (the JavaScript glue code to load the binary), and `hello.html` (a basic webpage to display the output).

## Running the Code

Because browsers have strict security policies around loading local files via JavaScript, you can't just double-click `hello.html`. We need to serve it over a local web server. 

Python makes this super easy:

```bash
python3 -m http.server
```

Now, open your browser and head to `http://localhost:8000/hello.html`. If everything went according to plan, you'll see a terminal-like console on the webpage printing: `Hello, WebAssembly!`.

## Wrapping up

This is obviously just the tip of the iceberg. Printing a string is fun, but the real power of WebAssembly comes from porting massive C++ codebases (like audio engines, physics simulators, or databases) directly into the browser. 

In future posts, I'll dive into more realistic use cases—like how I used Wasm and WebWorkers to build lock-free ring buffers for Chromium, passing complex memory structures back and forth between JavaScript and C++. 

Until then, happy hacking!

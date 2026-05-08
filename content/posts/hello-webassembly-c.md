---
title: "Hello WebAssembly: Getting Started with C/C++"
date: 2023-11-21T06:40:48Z
draft: false
tags: ["WebAssembly", "C", "C++", "Emscripten", "WASM"]
---

WebAssembly (often abbreviated as wasm) is a binary instruction format for a stack-based virtual machine. It's designed as a portable compilation target for programming languages, enabling deployment on the web for client and server applications. The power of WebAssembly lies in its ability to execute code at near-native speed, opening up a world of possibilities for web applications. Let’s dive deep into setting up the tools and writing our first WebAssembly module using C.

## What is WebAssembly?

WebAssembly acts as a bridge between high-performance code written in languages like C, C++, or Rust, and the web. Traditional web applications run entirely on JavaScript, which, while powerful, might not be the most efficient language for computationally intensive tasks. WebAssembly provides a fast, low-level binary format that browsers can execute, bringing near-native performance to web applications.

## Prerequisites

To embark on our WebAssembly journey, we need a set of tools to compile our C/C++ code into wasm format. The primary toolchain for this task is Emscripten. Emscripten compiles C/C++ code into WebAssembly and generates the necessary JavaScript and HTML glue code for seamless integration into web applications.

### Setting Up Emscripten

The first step is setting up Emscripten. Open your terminal and follow these commands:

```bash
# Clone Emscripten SDK repository
git clone https://github.com/emscripten-core/emsdk.git

# Enter the cloned directory
cd emsdk

# Install the latest Emscripten tools
./emsdk install latest

# Activate the installed tools
./emsdk activate latest

# Source the environment variables for your current terminal session
source ./emsdk_env.sh
```

With Emscripten installed and configured, we're ready to write and compile our C code.

## Writing C Code

Let's keep it simple for our first WebAssembly module. Create a file named `hello.c` with the following content:

```c
#include <stdio.h>

int main() {
    printf("Hello, WebAssembly!\n");
    return 0;
}
```

This C program simply prints a classic greeting to the standard output. Now, the magic happens when we compile this code using Emscripten.

## Compiling to WebAssembly

In your terminal, navigate to the directory containing your `hello.c` file and execute the following command:

```bash
emcc hello.c -o hello.html
```

Let's break down this command:

- `emcc`: The Emscripten Compiler Frontend.
- `hello.c`: Your input C file.
- `-o hello.html`: The output flag specifying that we want an HTML file. Emscripten will not only generate the WebAssembly binary (`hello.wasm`) but also the necessary JavaScript and HTML code (`hello.js` and `hello.html`) to run it in a browser.

Once the compilation is complete, you should find three new files in your directory: `hello.wasm`, `hello.js`, and `hello.html`.

## Running the WebAssembly Module

Now, let's see our WebAssembly module in action. Since browsers restrict fetching local files for security reasons, it's recommended to serve the generated files via a local server.

You can use a simple tool like Python's `http.server` or `live-server` for this purpose. Let's use Python:

```bash
python3 -m http.server
```

Open your web browser and navigate to `http://localhost:8000/hello.html`. You should see a webpage displaying the output of our C program: "Hello, WebAssembly!".

## Conclusion

We've covered the basics of WebAssembly, installed the necessary toolchain (Emscripten), written a simple C program, and successfully compiled and executed it in a web browser.

This is just the tip of the iceberg. WebAssembly opens the door to porting complex applications, games, and libraries to the web, pushing the boundaries of what is possible in the browser. In future posts, we'll explore more advanced topics, including passing data between JavaScript and WebAssembly, handling memory, and optimizing code for the web.

Happy coding with WebAssembly!

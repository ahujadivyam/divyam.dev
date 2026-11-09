---
title: "Running a C++ Snake Game in the Browser with WebAssembly"
date: 2024-06-20T10:00:00Z
draft: false
tags: ["WebAssembly", "C++", "GameDev", "Emscripten"]
---

Compiling "hello world" from C to WebAssembly is fun for five minutes, but printing text to an emulated terminal doesn't really tell you what it feels like to build something interactive in Wasm.

I wanted to see what happens when you take real desktop C++ game code and shove it into a browser tab. So I built [snake_wasm](https://github.com/ahujadivyam/snake_wasm)—a classic Snake clone written in C++17 using `olcPixelGameEngine`, compiled via Emscripten into a `.wasm` binary that draws directly to an HTML5 canvas at 60 fps. No JavaScript game logic, no hand-written canvas glue.

Here are the parts of the build that were actually interesting to solve.

## The Engine: olcPixelGameEngine

If you've ever set up a C++ graphics project from scratch, you know how annoying dependency management can get. Linking SDL2 or GLFW, hunting down OpenGL loaders, and fighting CMake configurations across OSes gets old fast.

For this, I used **olcPixelGameEngine** (by David Barr / Javidx9). It's an entire 2D game engine packed into a single header file (`olcPixelGameEngine.h`). You `#define OLC_PGE_APPLICATION`, include the header in one `.cpp` file, and you get windowing, keyboard polling, and primitive drawing without installing ten different system packages:

```cpp
#define OLC_PGE_APPLICATION
#include "olcPixelGameEngine.h"

class Snake : public olc::PixelGameEngine {
public:
    Snake() {
        sAppName = "Snake WASM";
    }

    bool OnUserCreate() override {
        ResetGame();
        return true;
    }

    bool OnUserUpdate(float fElapsedTime) override {
        HandleInput();
        UpdateState(fElapsedTime);
        Render();
        return true;
    }
};
```

You inherit from `olc::PixelGameEngine`, override `OnUserCreate()` for initialization and `OnUserUpdate()` for your frame step, and that's the whole harness. Even better: PGE has built-in support for Emscripten.

## Why Your Desktop Game Loop Freezes the Browser

On desktop, your game owns the thread. You typically write a blocking `while` loop that runs until the user closes the window:

```cpp
// Works on desktop. Freezes your browser tab instantly.
while (bGameRunning) {
    ProcessInput();
    UpdatePhysics();
    RenderFrame();
}
```

If you compile that loop straight to WebAssembly, your browser tab dies immediately.

Browsers are single-threaded and event-driven. If your WASM module sits in a tight `while(true)` loop, execution never returns to the browser's JavaScript engine. That means the browser can't process DOM events, can't repaint the canvas, and can't even close the tab cleanly.

To make C++ play nice with the browser, you have to hand control back to the browser on every single frame. Emscripten does this through `emscripten_set_main_loop()`:

```cpp
#ifdef __EMSCRIPTEN__
#include <emscripten.h>

void MainLoop() {
    game.Step();
}

int main() {
    emscripten_set_main_loop(MainLoop, 0, 1);
    return 0;
}
#endif
```

Passing `0` as the frame rate tells Emscripten to hook directly into the browser's `requestAnimationFrame` loop. Each time the screen is ready to paint (~60 times a second on a standard display), the browser calls your C++ frame step, lets you update positions and draw pixels, and then immediately reclaims the thread to do the actual layout and render.

PGE wraps this internally when compiling with `-s __EMSCRIPTEN__`, but understanding *why* you can't have an infinite loop in Wasm saves a lot of head-scratching when porting desktop code.

## A Couple of Annoying Bugs Worth Mentioning

### The 180-Degree Neck Snap
If you store the player's direction and update it immediately on keypress, you run into a classic Snake bug:
Suppose the snake is moving **Right**. The player quickly taps **Up**, then **Left** before the next game tick fires. Both key events process, so `dir` becomes `Left`. The game tick fires, the snake tries to move left into its own neck, and you die instantly.

The fix is buffering the desired direction and only committing it when the logical game tick advances:

```cpp
// In HandleInput():
if (GetKey(olc::Key::UP).bPressed && currentDir != DOWN) nextDir = UP;
if (GetKey(olc::Key::LEFT).bPressed && currentDir != RIGHT) nextDir = LEFT;

// In TickGameLogic():
currentDir = nextDir;
```

### Tick Rate vs. Refresh Rate
Your monitor might refresh at 60Hz, 120Hz, or 144Hz. If you advance the snake's position on every `OnUserUpdate()`, the game runs at twice the speed on a high-refresh monitor.

You have to decouple drawing from game logic by accumulating elapsed time:

```cpp
fSnakeTimer += fElapsedTime;
if (fSnakeTimer >= fSnakeSpeed) { // e.g. 0.12s per grid step
    fSnakeTimer -= fSnakeSpeed;
    TickGameLogic();
}
```

The game renders at the monitor's native framerate, but the snake only moves once every 120ms.

## How C++ Pixels Actually Reach the Canvas

When you call `FillRect()` or `Draw()` in PGE, how does that reach an HTML `<canvas>`?

1. PGE translates the draw call into standard OpenGL ES 2.0/3.0 commands.
2. Emscripten's runtime intercepts those GLES calls and translates them 1:1 into browser **WebGL 2** calls.
3. The browser passes the WebGL commands directly to your GPU.

So you aren't manually poking an array of RGBA bytes across the WASM boundary into an HTML canvas context. The graphics pipeline is hardware-accelerated the whole way through.

## The Emscripten Build Command

Here is the compiler invocation that puts it all together:

```bash
em++ -std=c++17 -O2 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s MAX_WEBGL_VERSION=2 \
    -s MIN_WEBGL_VERSION=2 \
    main.cpp \
    -o snake.html
```

A few flags that matter:
- `-s ALLOW_MEMORY_GROWTH=1`: Emscripten allocates a fixed 16MB heap by default. If your heap usage exceeds that, the app crashes with an out-of-memory error. This flag lets the linear memory page expand dynamically.
- `-s MAX_WEBGL_VERSION=2 -s MIN_WEBGL_VERSION=2`: Forces Emscripten to target WebGL 2 exclusively, stripping out old WebGL 1 fallback glue.
- `-o snake.html`: Emscripten generates `snake.wasm`, `snake.js` (the loader runtime), and a default HTML shell containing the `<canvas>`.

Start a quick static server:

```bash
python3 -m http.server
```

Open `localhost:8000/snake.html`, and you have a native C++ binary running inside a browser tab.

The full source is on GitHub: [github.com/ahujadivyam/snake_wasm](https://github.com/ahujadivyam/snake_wasm)

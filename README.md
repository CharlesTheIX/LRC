# LRC

LRC is a parent-focused tracker for Lea Rose Charles, a newborn baby. Written in [Zig](https://ziglang.org), it is being built to record feeds and other day-to-day care information. It ships with a [raylib](https://www.raylib.com)-powered UI as well as lightweight HTTP and UDP server components.

This README is written for people who have **never installed or used Zig before** — follow it top to bottom and you'll go from a bare machine to a running app.

## 📚 Table of Contents

- [LRC](#lrc)
  - [📚 Table of Contents](#-table-of-contents)
  - [✨ Overview](#-overview)
  - [🧰 Prerequisites](#-prerequisites)
  - [⚡ Installing Zig](#-installing-zig)
    - [Option A: Download a prebuilt release (recommended)](#option-a-download-a-prebuilt-release-recommended)
    - [Option B: Install via a version manager](#option-b-install-via-a-version-manager)
    - [Verifying your install](#verifying-your-install)
  - [📥 Getting the Project](#-getting-the-project)
  - [🏗️ Building the Project](#️-building-the-project)
  - [▶️ Running the Application](#️-running-the-application)
    - [Run the LRC UI app](#run-the-lrc-ui-app)
    - [Run the UDP server](#run-the-udp-server)
    - [Run the HTTP server](#run-the-http-server)
    - [No arguments / help](#no-arguments--help)
  - [🗂️ Project Structure](#️-project-structure)
  - [💾 Configuration \& Data Storage](#-configuration--data-storage)
  - [📦 Dependencies](#-dependencies)
  - [🧪 Development Workflow](#-development-workflow)
  - [🛠️ Troubleshooting](#️-troubleshooting)
  - [📄 License](#-license)

## ✨ Overview

LRC is a single Zig binary that exposes three sub-commands:

| Command       | Description                                    |
| ------------- | ---------------------------------------------- |
| `lrc`         | Runs the Lea Rose Charles tracker (raylib UI). |
| `udp-server`  | Starts the standalone UDP server component.    |
| `http-server` | Starts an HTTP server on port `8080`.          |

The project is built entirely with Zig's native build system (`build.zig`) — there is no separate Makefile, CMake, or package manager involved for the app itself.

## 🧰 Prerequisites

Before you start, make sure you have:

- A terminal (macOS Terminal, iTerm2, etc.)
- [Git](https://git-scm.com/downloads) installed (`git --version` to check)
- ~200 MB of free disk space (for the Zig compiler and cached dependencies)
- An internet connection the **first** time you build, since Zig will fetch dependencies (raylib, etc.)

You do **not** need any prior Zig experience — this guide covers installation from scratch.

## ⚡ Installing Zig

This project targets **Zig `0.16.0`** or newer (see the `minimum_zig_version` field in [build.zig.zon](build.zig.zon)). Zig's package manager is strict about versions, so try to match this as closely as possible.

### Option A: Download a prebuilt release (recommended)

1. Go to the official Zig downloads page: <https://ziglang.org/download/>
2. Download the archive for your OS/architecture (macOS users: pick the `aarch64-macos` build for Apple Silicon, or `x86_64-macos` for Intel).
3. Extract it somewhere permanent, e.g.:
   ```sh
   mkdir -p ~/zig
   tar -xf zig-*.tar.xz -C ~/zig --strip-components=1
   ```
4. Add Zig to your `PATH` so you can run it from anywhere. Add this line to your `~/.zshrc` (macOS default shell):
   ```sh
   echo 'export PATH="$HOME/zig:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Option B: Install via a version manager

If you'd rather manage multiple Zig versions, use a version manager such as [zvm](https://www.zvm.app) or [zigup](https://github.com/marler8997/zigup):

```sh
# Using zvm (https://www.zvm.app)
curl https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash
zvm install 0.16.0
zvm use 0.16.0
```

### Verifying your install

Run:

```sh
zig version
```

You should see `0.16.0` (or newer) printed. If you get a "command not found" error, double-check that the directory containing the `zig` binary is on your `PATH`.

## 📥 Getting the Project

Clone the repository:

```sh
git clone https://github.com/CharlesTheIX/LRC.git
cd LRC
```

## 🏗️ Building the Project

From the project root, run:

```sh
zig build
```

The first build will take longer than subsequent ones because Zig needs to **fetch and compile dependencies** (currently [raylib-zig](https://github.com/raylib-zig/raylib-zig), which is declared in [build.zig.zon](build.zig.zon)). This requires network access.

On success, the compiled binary is placed at:

```
zig-out/bin/lrc
```

You can build an optimized release build with:

```sh
zig build -Doptimize=ReleaseFast
```

Other optimization modes: `Debug` (default), `ReleaseSafe`, `ReleaseSmall`.

## ▶️ Running the Application

You can either run the built binary directly, or use the `zig build run` step, which builds and runs in one command and lets you forward arguments after `--`.

### Run the LRC UI app

```sh
zig build run -- lrc
# or, after building:
./zig-out/bin/lrc lrc
```

### Run the UDP server

```sh
zig build run -- udp-server
# or, after building:
./zig-out/bin/lrc udp-server
```

### Run the HTTP server

```sh
zig build run -- http-server
# or, after building:
./zig-out/bin/lrc http-server
```

The HTTP server listens on all network interfaces at port `8080` and currently responds to every request with plain-text `Hello, World!`.

### No arguments / help

Running the binary with no recognized sub-command prints usage help:

```sh
./zig-out/bin/lrc
```

```
Usage: lrc <command>
Commands:
  udp-server   Run the UDP server
  http-server  Run the HTTP server
  lrc          Run the LRC application
```

## 🗂️ Project Structure

```
build.zig            # Zig build script — defines modules, executable, and build steps
build.zig.zon         # Package manifest — name, version, dependencies
assets/
  fonts/              # Fonts bundled with the app (e.g. JetBrains Mono)
  audio/
    music/            # Background music tracks
    sfx/               # Short sound effects (e.g. click)
src/
  main.zig            # Entry point — parses the sub-command and dispatches
  root.zig            # Shared "app" module (Command enum, help text)
  lib/
    lrc/
      root.zig        # Lea Rose Charles tracker core
      utils.zig       # Shared io helpers (file/dir create, read, write, Z-slice conversion)
      lib/
        baby_data/    # Body + feeding item models, parsing, and file-backed persistence
        config/       # Config helper (not initialized by the app yet)
        date_time/    # Date/time utilities
        timer/        # Timer utilities
        ui/           # raylib UI: screens, text/number/select/textarea inputs, buttons, audio
    http/
      root.zig        # Standalone HTTP server
    udp/
    root.zig          # Standalone UDP server component
```

## 💾 Configuration & Data Storage

The `lrc` command reads and writes Lea Rose Charles's data relative to your home directory (`$HOME`), not the directory from which the binary is run. Before the first run, create its data directory:

```sh
mkdir -p ~/.lrc_database
```

On first launch, LRC creates two files under `~/.lrc_database/`:

- `body_items.z` — body-related records (urinations, defecations, weight, notes) with a format header.
- `feeding_items.z` — feeding records (duration, type, feeder, amount, notes) with a format header.

The configuration helper exists but is not currently initialized by the application, so no `.lrc_config` file is created.

## 📦 Dependencies

Dependencies are declared in [build.zig.zon](build.zig.zon) and downloaded/cached automatically by Zig's package manager the first time you build:

- [raylib-zig](https://github.com/raylib-zig/raylib-zig) — Zig bindings for [raylib](https://www.raylib.com), used to render the UI.

You don't need to install raylib yourself — Zig fetches and builds it as part of `zig build`. If you ever need to force a re-fetch of dependencies, delete the local package cache:

```sh
rm -rf ~/.cache/zig
zig build
```

## 🧪 Development Workflow

Common commands while working on the codebase:

```sh
zig build              # Compile the project
zig build run -- lrc   # Build and run the LRC app
zig build -Doptimize=Debug   # Explicit debug build (default)
zig fmt src/            # Auto-format all Zig source files
```

## 🛠️ Troubleshooting

- **`zig: command not found`** — Zig isn't on your `PATH`. Revisit [Installing Zig](#-installing-zig).
- **Version mismatch errors when building** — Check `zig version` against `minimum_zig_version` in [build.zig.zon](build.zig.zon); install a matching Zig release.
- **Build fails while fetching dependencies** — Make sure you have an active internet connection; corporate proxies/VPNs can sometimes block Zig's package fetcher.
- **raylib/graphics window doesn't open** — Ensure you're not running in a headless environment (e.g. SSH without a display); raylib needs access to a windowing system (Cocoa on macOS).

## 📄 License

No license file is currently included in this repository. Contact the repository owner ([CharlesTheIX](https://github.com/CharlesTheIX)) for usage terms.

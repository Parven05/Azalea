# Azalea

A vulkan renderer written in C++17.

## 1. Install dependencies (Arch Linux)

```bash
sudo pacman -S --needed base-devel git cmake ninja vulkan-devel sdl3
```

Check that Vulkan works:

```bash
sudo pacman -S vulkan-tools
vulkaninfo --summary
```

## 2. Clone the repo

```bash
git clone <your-repo-url>
cd <your-repo-folder>
```

## 3. Build and run

Make the script executable once:

```bash
chmod +x build.sh
```

Then use it:

```bash
./build.sh              # debug build
./build.sh -r           # release build
./build.sh -c           # clean
./build.sh -x           # debug build and run
./build.sh -r -x        # release build and run
```
The executable is placed in `bin/main`.
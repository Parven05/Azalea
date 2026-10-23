# Azalea

A vulkan renderer written in C++17.

## 1. Install dependencies

```bash
# arch linux
sudo pacman -S --needed base-devel git cmake ninja vulkan-devel sdl3
```

## 2. Clone the repo

```bash
git clone https://github.com/Parven05/Azalea.git
cd Azalea
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
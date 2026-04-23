FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update

RUN apt install -y --no-install-recommends \
        ca-certificates apt-utils wget curl \
        lsb-release zip

RUN apt install -y --no-install-recommends \
        build-essential git make cmake \
        pkg-config ninja-build

# SDL2 build dependencies — focal's libsdl2-dev is too old for the Mania decomp,
# so build.txt builds SDL2 2.32 from source to link the game against. These
# are the subsystem dev headers SDL2's own build needs. The built SDL2 is NOT
# shipped in the port zip — devices provide libSDL2-2.0.so.0 at runtime.
RUN apt install -y --no-install-recommends \
        libasound2-dev libpulse-dev \
        libaudio-dev libjack-dev libsndio-dev libx11-dev libxext-dev \
        libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev \
        libxkbcommon-dev libdrm-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev \
        libegl1-mesa-dev libdbus-1-dev libibus-1.0-dev libudev-dev fcitx-libs-dev \
        libwayland-dev

# Sonic Mania Decompilation dependencies
RUN apt install -y --no-install-recommends \
        libglew-dev libglfw3-dev libtheora-dev

# Newer CMake (focal's is 3.16)
RUN wget https://github.com/Kitware/CMake/releases/download/v3.31.3/cmake-3.31.3-linux-`uname -m`.sh
RUN chmod a+x ./cmake-3.31.3-linux-`uname -m`.sh
RUN ./cmake-3.31.3-linux-`uname -m`.sh --prefix=/usr/local --exclude-subdir --skip-license

WORKDIR "/root"

CMD ["bash"]

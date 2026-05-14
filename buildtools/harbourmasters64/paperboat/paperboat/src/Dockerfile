FROM rhh-base

# Clang-18 toolchain via the upstream LLVM apt script — focal's clang lags
# upstream point releases, and pinning all HM64 ports to clang-18 keeps the
# toolchain consistent across SoH / 2s2h / Starship / SpaghettiKart / etc.
RUN apt update && apt install -y --no-install-recommends \
        gnupg software-properties-common
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 18 && \
    rm llvm.sh

# Autotools (opusfile's build), explicit libstdc++ version pin.
RUN apt install -y --no-install-recommends \
        libstdc++-10-dev autoconf automake libtool

# Common dev libs across all HM64 ports.
RUN apt install -y --no-install-recommends \
        libpng-dev libzip-dev \
        libogg-dev libvorbis-dev \
        libssl-dev \
        libboost-dev libopengl-dev \
        nlohmann-json3-dev libtinyxml2-dev libspdlog-dev \
        zipcmp zipmerge ziptool

ENV CC=clang-18
ENV CXX=clang++-18
ENV LD=lld-18

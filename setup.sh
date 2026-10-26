#!/bin/bash
set -e

WORKSHOP_DIR="$HOME/workshop_baremetal"
NO_OS_REPO="https://github.com/analogdevicesinc/no-OS.git"
NO_OS_COMMIT="a63095e3d365f6612f78b0fd8204a6ba5afd5fd2"

OPENOCD_REPO="https://github.com/analogdevicesinc/openocd.git"
OPENOCD_BRANCH="0.12.0-1.4.0"

MSDK_REPO="https://github.com/analogdevicesinc/msdk.git"
MSDK_COMMIT="fbcdf639d7deea2e518108b0a82b50b3a8a4c2f3"

# checkout_pinned <dir> <repo> <commit>
# Shallow-fetch exactly one commit into <dir> and check it out detached.
checkout_pinned() {
    local dir="$1" repo="$2" commit="$3"

    if [ ! -d "$dir/.git" ]; then
        git init "$dir"
        git -C "$dir" remote add origin "$repo"
    fi

    if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" != "$commit" ]; then
        echo "checking out $(basename "$dir") $commit"
        git -C "$dir" fetch --depth 1 origin "$commit"
        git -C "$dir" checkout --detach FETCH_HEAD
    else
        echo "$(basename "$dir") already at $commit"
    fi
}

if [ ! -f /etc/udev/rules.d/99-daplink.rules ]; then
    echo "configuring daplink udev rules"
    sudo tee /etc/udev/rules.d/99-daplink.rules << 'EOF'
# DAPLink/CMSIS-DAP - USB interface
SUBSYSTEM=="usb", ATTR{idVendor}=="0d28", ATTR{idProduct}=="0204", MODE="0666"

# DAPLink/CMSIS-DAP - HID interface
KERNEL=="hidraw*", ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", MODE="0666"
EOF
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    sudo usermod -a -G dialout,plugdev,tty "$USER"
else
    echo "daplink udev rules already exist"
fi

echo "installing os dependencies"
sudo apt update
sudo apt install -y \
    git \
    build-essential \
    autoconf \
    automake \
    texinfo \
    cmake \
    ninja-build \
    make \
    libtool \
    pkgconf \
    libjim-dev \
    gcc-arm-none-eabi \
    libusb-0.1-4 \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libftdi-dev \
    libftdi1-dev \
    libgpiod2 \
    libhidapi-dev \
    libhidapi-libusb0 \
    picocom \
    python3-pygame

mkdir -p "$WORKSHOP_DIR"

checkout_pinned "$WORKSHOP_DIR/no-OS" "$NO_OS_REPO" "$NO_OS_COMMIT"
checkout_pinned "$WORKSHOP_DIR/msdk" "$MSDK_REPO" "$MSDK_COMMIT"

# Expose the workshop project inside no-OS so its build system can find it
if [ -e "$WORKSHOP_DIR/no-OS/projects/workshop" ] && [ ! -L "$WORKSHOP_DIR/no-OS/projects/workshop" ]; then
    echo "no-OS/projects/workshop exists and is not a symlink, leaving it alone"
else
    ln -sfn "$WORKSHOP_DIR/workshop" "$WORKSHOP_DIR/no-OS/projects/workshop"
fi

# This modifies a tracked file. If NO_OS_COMMIT is changed later and the new
# commit touches projects/Kconfig, run
#   git -C no-OS checkout -- projects/Kconfig
# before re-running this script.
NO_OS_KCONFIG="$WORKSHOP_DIR/no-OS/projects/Kconfig"
if ! grep -qF 'source "projects/workshop/Kconfig"' "$NO_OS_KCONFIG"; then
    echo "adding workshop to no-OS projects/Kconfig"
    sed -i '/^endmenu/i source "projects/workshop/Kconfig"' "$NO_OS_KCONFIG"
fi

if [ ! -x "$WORKSHOP_DIR/openocd/src/openocd" ]; then
    echo "building openocd from source..."

    if [ ! -d "$WORKSHOP_DIR/openocd" ]; then
        git clone --depth 1 -b "$OPENOCD_BRANCH" "$OPENOCD_REPO" "$WORKSHOP_DIR/openocd"
    fi

    cd "$WORKSHOP_DIR/openocd"
    ./bootstrap
    ./configure
    make -j"$(nproc)"
fi

# The no-OS maxim toolchain looks for OpenOCD in $MAXIM_LIBRARIES/../Tools/OpenOCD
# (openocd binary + scripts dir), so link the locally built one there.
OPENOCD_TOOLS="$WORKSHOP_DIR/msdk/Tools/OpenOCD"
mkdir -p "$OPENOCD_TOOLS"
ln -sfn "$WORKSHOP_DIR/openocd/src/openocd" "$OPENOCD_TOOLS/openocd"
ln -sfn "$WORKSHOP_DIR/openocd/tcl" "$OPENOCD_TOOLS/scripts"

echo "setup complete, log out and back in for USB group changes to take effect"

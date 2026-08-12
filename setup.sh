#!/bin/bash
set -e

WORKSHOP_DIR="$HOME/workshop_baremetal"
NO_OS_REPO="https://github.com/tvlad1234/no-OS.git"
NO_OS_BRANCH="workshop"

OPENOCD_REPO="https://github.com/analogdevicesinc/openocd.git"
OPENOCD_BRANCH="0.12.0-1.4.0"

MSDK_REPO="https://github.com/analogdevicesinc/msdk.git"

if [ ! -f /etc/udev/rules.d/99-daplink.rules ]; then
    sudo tee /etc/udev/rules.d/99-daplink.rules << 'EOF'
# DAPLink/CMSIS-DAP - USB interface
SUBSYSTEM=="usb", ATTR{idVendor}=="0d28", ATTR{idProduct}=="0204", MODE="0666"

# DAPLink/CMSIS-DAP - HID interface  
KERNEL=="hidraw*", ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", MODE="0666"
EOF
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    sudo usermod -a -G dialout,plugdev,tty $USER
else
    echo "daplink udev rules already exist"
fi

sudo apt update
sudo apt install -y \
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

if [ -d "$WORKSHOP_DIR/no-OS" ]; then
    echo "no-OS already exists, skipping"
else
    cd "$WORKSHOP_DIR"
    git clone -b "$NO_OS_BRANCH" "$NO_OS_REPO"
fi

if ! command -v openocd >/dev/null 2>&1; then
    echo "openocd not found, building from source..."
    cd "$WORKSHOP_DIR"

    if [ -d "$WORKSHOP_DIR/openocd" ]; then
        echo "openocd repo already exists"
    else
        git clone --depth 1 -b "$OPENOCD_BRANCH" "$OPENOCD_REPO"
    fi

    cd openocd
    ./bootstrap
    ./configure
    make -j$(nproc)
    sudo make install
fi

if [ -d "$WORKSHOP_DIR/msdk" ]; then
    echo "msdk already exists, skipping"
else
    cd "$WORKSHOP_DIR"
    git clone --depth 1 "$MSDK_REPO"
fi

LINE="export MAXIM_LIBRARIES=$WORKSHOP_DIR/msdk/Libraries"
BASHRC="$HOME/.bashrc"

if ! grep -qxF "$LINE" "$BASHRC"; then
   echo "$LINE" >> "$BASHRC"
   echo "Added MAXIM_LIBRARIES to $BASHRC"
else
     echo "MAXIM_LIBRARIES already set in $BASHRC"
fi

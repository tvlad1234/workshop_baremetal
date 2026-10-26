# Workshop Project

Embedded software examples for MAX78000FTHR using the no-OS framework.

**Prerequisites:** Complete the setup in `~/workshop_baremetal/README.md` first.

## Quick Start

`MAXIM_LIBRARIES` is already exported by the workshop setup script - no manual environment setup needed.

```bash
# From the no-OS repository root
cd ~/workshop_baremetal/no-OS

# Build and flash
python tools/scripts/no_os_build.py build \
    --project workshop --variant example_1 --board max78000fthr \
    --probe openocd --flash
```

**For detailed workshop instructions, see [HANDS_ON.md](HANDS_ON.md)**

## Project Structure

```text
.
├── HANDS_ON.md            # Workshop guide
├── CMakeLists.txt         # Build system (sources per example)
├── Kconfig                # Example selection menu
├── *.conf                 # Defconfig per example (example_1.conf, ...)
├── boards/                # Per-board overlay for each example
│   └── <example>/max78000fthr.conf
├── README.md              # This file
└── src/
    ├── common/
    │   ├── common_data.c  # Shared initialization
    │   └── common_data.h  
    ├── examples/
    │   ├── example_1/     # UART Hello World
    │   ├── example_2/     # SPI sensor reading
    │   ├── example_3/     # Data conversion
    │   └── iio_example/   # IIO framework demo
    └── platform/
        └── maxim/
            ├── main.c           # Entry point
            ├── parameters.c     # Platform config
            └── parameters.h     # Peripheral/device config
```

## Build System

This project uses the no-OS CMake build flow. Each example is a `--variant`
of the `workshop` project; `tools/scripts/no_os_build.py` selects the right
board preset and defconfig for you. Run these from the no-OS repository root.

### Commands

```bash
# See available variant/board combinations
python tools/scripts/no_os_build.py list --project workshop

# Build only
python tools/scripts/no_os_build.py build \
    --project workshop --variant <name> --board max78000fthr

# Build and flash to board
python tools/scripts/no_os_build.py build \
    --project workshop --variant <name> --board max78000fthr \
    --probe openocd --flash

# Clean rebuild
python tools/scripts/no_os_build.py build \
    --project workshop --variant <name> --board max78000fthr --clean
```

Build artifacts (`.elf`, `.hex`, `.bin`) land in
`build/workshop-<name>-max78000fthr/build/` at the repo root.

### Available Examples

| Variant | Description |
|---------|-------------|
| `example_1` | UART Hello World - verifies toolchain |
| `example_2` | SPI sensor communication |
| `example_3` | Fixed-point math and conversion |
| `iio_example` | IIO framework demonstration |

**Note:** Example 4 (IIO streaming) is covered in HANDS_ON.md with additional setup steps.

### Build Tips

- **Switching examples?** Each variant builds into its own
  `build/workshop-<variant>-max78000fthr` directory, so there's nothing to
  clean between examples - just change `--variant`.
- **Stale build?** Add `--clean` to remove the build directory before
  reconfiguring.
- **Faster builds:** add `--jobs $(nproc)`
- **Manual `cmake`/`ninja` invocation:** see the [Maxim CMake build guide](https://analogdevicesinc.github.io/no-OS/build_guides/build_maxim_cmake.html).

## Hardware Reference

### MAX78000FTHR Specs

- **MCU:** MAX78000 (ARM Cortex-M4 @ 100MHz)
- **Memory:** 512KB Flash, 128KB SRAM
- **Programming:** USB via CMSIS-DAP

### Peripheral Configuration

`src/platform/maxim/parameters.h` selects the peripheral instances and
settings used by the examples - it does not define physical pin numbers
(those are fixed by the MAX78000FTHR's UART0/SPI1 routing; see the wiring
table below):

```c
// UART (USB serial console)
#define UART_DEVICE_ID   0          // UART0
#define UART_BAUDRATE    57600

// SPI (sensor communication)
#define SPI_DEVICE_ID    1          // SPI1
#define SPI_CS           1          // chip-select index
#define SPI_BAUDRATE     1000000    // 1 MHz
```

### ADXL355 Wiring

For Examples 2-4, connect to the physical pins below (fixed by SPI1's
routing on the MAX78000FTHR - not configurable in `parameters.h`):

| MAX78000FTHR | Signal | ADXL355 Pin |
|--------------|--------|-------------|
| 3V3          | Power  | 6 or 12     |
| GND          | Ground | 5 or 11     |
| P0_11        | CS     | 1           |
| P0_5         | MOSI   | 2           |
| P0_6         | MISO   | 3           |
| P0_7         | SCK    | 4           |
| P0_19        | DRDY   | 10 (optional) |

**Wiring tips:**

- Connect power first, then signals
- Keep wires short
- Double-check before powering on

## Serial Console

### Connect to Board

Find your device:

```bash
ls /dev/ttyACM* /dev/ttyUSB*
```

Connect with picocom:

```bash
picocom -b 57600 /dev/ttyACM0
```

**Exit:** `Ctrl+A` then `Ctrl+X`

Or with screen:

```bash
screen /dev/ttyACM0 57600
```

**Exit:** `Ctrl+A` then `K` then `Y`

### Serial Settings

- Baud: 57600
- Data: 8N1 (8 bits, no parity, 1 stop bit)
- Flow control: None

## Creating New Examples

Adding a new example means adding a new `--variant` to the `workshop`
project. That takes four pieces:

1. **Source file:**

   ```bash
   mkdir -p src/examples/my_example
   cp src/examples/example_1/example_1.c src/examples/my_example/my_example.c
   ```

2. **Defconfig** at `my_example.conf` (project root), listing the Kconfig
   symbols the example needs plus its own selector, e.g.:

   ```text
   CONFIG_UART=y
   CONFIG_IRQ=y
   CONFIG_DMA=y
   CONFIG_SPI=y
   CONFIG_ACCEL=y
   CONFIG_ACCEL_ADXL355=y
   CONFIG_WORKSHOP_MY_EXAMPLE=y
   ```

3. **Kconfig entry** - add a `config WORKSHOP_MY_EXAMPLE` choice option in
   `Kconfig`, following the pattern of the existing `WORKSHOP_EXAMPLE_*`
   entries.

4. **CMakeLists.txt entry** - add an `if(CONFIG_WORKSHOP_MY_EXAMPLE)` block
   that adds `src/examples/my_example/my_example.c` to `target_sources`,
   following the pattern used for `CONFIG_WORKSHOP_EXAMPLE_1`.

**Key points:**

- Keep `example_main()` as entry point (not `main()`)
- Use `adxl355_uart_ip` for UART (from common_data.h)
- Use `adxl355_spi_ip` and `adxl355_ip` for sensor
- Follow error handling pattern with `goto error`

**Build:**

```bash
python tools/scripts/no_os_build.py build \
    --project workshop --variant my_example --board max78000fthr \
    --probe openocd --flash
```

### Example Structure

Study `src/examples/example_1/example_1.c` for the pattern:

```c
int example_main()
{
    int ret;

    // Initialize UART for console
    ret = no_os_uart_init(&uart_desc, &adxl355_uart_ip);
    if (ret)
        goto error;

    // Your code here

error:
    // Cleanup
    no_os_uart_remove(uart_desc);
    return ret;
}
```

## Documentation

- **HANDS_ON.md** - Detailed workshop guide
- **no-OS API:** <https://analogdevicesinc.github.io/no-OS/>
- **MAX78000 User Guide:** <https://www.analog.com/max78000>
- **ADXL355 Datasheet:** <https://www.analog.com/adxl355>

---

**Ready to start?** Open [HANDS_ON.md](HANDS_ON.md) for the workshop guide!
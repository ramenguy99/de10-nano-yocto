## Yocto:

- Multiple ways to configure a yocto build, recommended way is inside source directory (e.g. poky), but this is inconvenient if you want poky as a submodule.
- Simplest way I found is to keep all layers in /sources (or any other directory structure), init build env with:

  ```
  . ./path/to/poky/oe-init-build-env ./build
  ```

  and then modify build/conf.local.conf with things like:
  - machine
  - directories (tmp, sstate, downloads, etc..)
  - customizations (distro, distro_features, bbmask, init_manager and virtual-runtime_init_manager)
  - bsp specific config (uboot, kernel provider, devicetree)

## Build instructions

```
. sources/poky/oe-init-build-env
bitbake console-image-minimal
```

## Quartus instructions

- Download and install Quartus from: https://www.altera.com/downloads/fpga-development-tools/quartus-prime-lite-edition-design-software-version-25-1-linux
- Open quartus `.qpf` project
- Open platform designer and generate the system design from the `.qsys`.
- Run up to the Assembler step
- Export programming file: File > Convert Programming files > set type to `.rbf`> select Passive Parallel x8 > Select SOF Data in table > Add file > Select `output_files/DE10_NANO_SoC_GHRD.sof` > Generate


## Notes:

### Build issues:
- Build was failing in different ways with multiple kernels -> 6.6 lts seems to work fine (specified by linux-socfpga-lts)
- DTB file for boot partition is picked by IMAGE_BOOT_FILES variable, it was using the same path as in the kernel sources, but this does not work because it's installed with the basename instead of the full path.

#### Interesting config:
- WKS_FILE: for configuring partition layout
- IMAGE_BOOT_FILES: contents of /boot -> carefull this does no rerun if some files change (tested with u-boot.scr).

#### TODO:
- [x] fix absolute paths for bbmask in layer.conf
- [x] explore boot image contents
  - p1: boot (zImage, dtb, extlinux)
  - p2: rootfs
  - p3: uboot-with-spl.sfp
- [x] cyclone5-gsrd image conf is not being applied, not sure how that's supposed to work
  - needed to do some manual changes to meta-intel-fpga-refdes
    - broken bash
    - broken links
- [x] Currently can build with golden design, technically being flashed a boot by u-boot. Interesting that we are using
      ${loadaddr} for loading. Not sure what we prefer here, likely flashing after booting is better anyways.
      I think steps would be:
      - build without design and do not flash -> test linux only (also uboot serial and stuff)
      - build with design and check that it's being flashed (look into if we have any observable state)
      - build without design and try to flash from running board
      - make and test our own design
      - check if we can reflash at runtime, maybe adding/removing device overlays for hot-pluggable devices
- [x] gitignore + commit to git in a way that it's easy to reproduce stuff (e.g. submodules + build/conf)
- [x] make my own layer
- [ ] explore:
    - how to configure uboot -> currently dropping into shell, also not sure how to edit environment and ensure script is running
      - CONFIG: easiest way is to patch it to add / modify a defconfig, in our case it's the de-nano10-soc_defconfig
      - ENV: use CONFIG_ENV_SOURCE_FILE to provide our own source (example of this in u-boot-socfpga-env)
        - notes on boot environment:
          - at compile time:
            - a version of the environment is baked into the u-boot partition
            - this version can also be reloaded with env default -a
            - this comes from a .env file in uboot source (defined per board)
            - otherwise from the C source (known as old method in the docs)
            - check if we can use this mechanism to customize the environment, and if we can specify only some -> complex because it requires multiple files to define a board
            - decided to use a uboot.env file generated with mkenvimage and manually flash it
          - with script:
            - the environment can also be sourced from a file by u-boot. Not sure how to configure this yet.
          - at runtime:
            - boot environment for us lives on MMC, this is set by CONFIG_ENV_IS_IN_MMC (other media exists)
            - where exactly depends on CONFIG_ENV_OFFSET and CONFIG_ENV_SIZE (meaning depends on media, for MMC is absolute in bytes)
            - for de10-nano its 8kb, those 8kb are saved by the recipe u-boot-socfpga-env.bb to uboot.env (+ symlinks)
            - these are NOT part of the wic file, therefore they must be dded independently (sudo dd bs=1 count=8192 if=uboot.env skip=0 of=/dev/sda seek=17408)
            - this boot environment can be overwritten by cmd "env save" (dumps the current env)
            - if boot environment CRC is correct (e.g. a valid one is was flashed or saved and is found, it will replace completely the default (not just merge))
      - SCRIPT: see u-boot-socfpga-scr for example -> modified environment to first search for scripts and execute them. Also boot with extlinux from the same script.
    - how to patch sources of a recipe
      - devtool modify <recipe>
      - devtool update-recipe -a ../sources/meta-de10-nano <recipe> (from workspace directory)
      - devtool reset <recipe>
    - Kernel:
      - add devicetree with patch + KERNEL_DEVICETREE (in local.conf)
      - add config fragments also with .cfg patches (see https://docs.yoctoproject.org/kernel-dev/common.html#changing-the-configuration)
      - [ ] add kernel modules
    - Partition layout
        - override WKS_FILE
    - FPGA bridges:
      - 4 bridges:
        - hps2fpga    -> low latency MMIO HPS to FPGA
        - fpga2hps    -> low latency writebacks FPGA to HPS
        - lwhps2fpga  -> high latency MMIO HPS to FPGA
        - fpga2sdram  -> direct connection to sdram FPGA to SDRAM
      - Must be enabled in devicetree -> results in register writes and io mapping
    - Network over USB
      - Two options:
        - Default configuration usb config 
          - CONFIG_USB_G_NCM=y in .cfg file (bbappend to your kernel)
          - usb0 is automatically created on boot
        - USB configuration through configfs (hard mode)
          - USB controller that supports this -> can be see in /sys/class/udc (usb device controller)
          - Confguration in configfs tree (/sys/kernel/config) -> ids, functions etc.., UDC is then bound to this configuration
          - Various kernel config options and module required depending on function
      - Systemd .network file can be used for network configuration configure DHCP / DNS etc..
    - IRQs:
      - cat /proc/interrupts -> number on left, chip name + number on right
      - "interrupt-controller" in device tree specifies a controller
        - "#interrupt-cells" specifies how many numbers needed to specify an interrupt
        - description usually in devicetree binding docs in kernel source
        - for de10 nano we use cortex-a9-gic which has 3 address cells
          - type: 
            - 0: SPI (shared processor interrupt)
            - 1: PPI (per processor interrupt)
            - 2: SGI (software generated interrupt)
          - number (controller number)
          - flags:
            - 1: edge low-to-high
            - 2: edge high-to-low (no SPI)
            - 4: level high
            - 8: level low (no SPI)
        - nodes that use a controller specify "interrupt-parent", for us specified at soc level, inherited by child nodes.
        - each device specifies this in "interrupts"
      - kernel represents irqs with the following types:
        - irq_data:
          - irq number
          - irq_chip*
          - irq_domain*
        - irq_desc: 
          - irq_data
      - on the cyclone 5 interrupt numbers are described in chapter 10-13 (Generic Interrupt Controller)
      - interrupt number 72-135 are dedicated for fpga (Level or edge)
        and map to fpga-hps-irq0 (0-31) and fpga-hps-irq1(32-63)
      - example dt:
      ```
        / {
            soc{
              mysoftip {
                compatible="mysoftip";
                interrupts=<GIC_SPI 40 IRQ_TYPE_EDGE_RISING>;
                // interrupts=<0 40 1>;
              };
            };
        };
      ```
    - DMA:
      - ARM pl330 DMA controller (DMAC in Cyclone manual)
      - Has 8 channels and 32 request interfaces (first 8 can be used by FPGA, configured in quartus)
      - Can do dev/mem, mem/dev and mem/mem transfers
      - DMA controller driver uses the DMA Engine Linux subsystem to register a dma_device.
      - Uses the memory mapped register of the controller to handle dispatching requests.
      - Uses multiple threads to service DMA channels
      - According to block diagram communication with FPGA goes like this:
        FPGA <-> F2H/H2F Bridget <-> 64bit AXI <-> L3 switch <-> DMAC <-> L4 32 bit bus <-> SDRAM Controller
      - Different path from direct FPGA SDRAM access (likely the direct one can achieve higher throughput)
      - Can be used by peripherals devices (in our minimal example only UART, also uart0 is kernel console which for 8250 driver is not allowed to do DMA)
      - More of a general-purpose controller that can be used to offload some transfers.
      - Some devices (e.g. the Ethernet MACs, can also do their own DMA)
    - FPGA SDRAM access:
      - Initialization procedure:
        - There is a lot of messy / old information online on this topic, including old u-boot commands
          and different approaches depending what bootloader sequence is in use. The tools also changed
          and what artifacts are generated by which tool and the correct way to use them changed.
        - Altera documents the initialization procedure for correct FPGA2SDRAM bridge initialization:
          - https://community.altera.com/kb/knowledge-base/how-can-i-enable-the-fpga2sdram-bridge-on-cyclone-v-soc-and-arria-v-soc-devices/345342
          - https://support.criticallink.com/redmine/projects/mityarm-5cs/wiki/Important_Note_about_FPGAHPS_SDRAM_Bridge
        - Steps for future reference:
          1. First, the FPGA ports on the fpga2sdram peripheral must be placed in reset. This is accomplished by writing a zero to the FPGAPORTRST register in the SDRAM Controller control group.
          2. Second, the FPGA must be configured with an image that includes the configuration of the fpga2sdram ports. The FPGA fabric asserts configuration input ports at the input to the fpga2sdram bridges. The configuration ports affect such things as the width of the port as well as the direction, etc. When the FPGA is not configured, these configuration inputs are not defined.
          3. Third, once the configuration inputs are set, the configuration must be then latched / applied to the fpga2sdram bridge peripheral. This is accomplished by writing a one to the APPLYCFG bit in the STATICCFG register in the SDRAM Controller control group. This bit can only be written to while the SDRAM DDR interface is guaranteed to be completely IDLE (including transfers from the ARM cores, DMAs, etc.).
          4. Finally, the FPGA ports on the fpga2sdram peripheral can be taken out of reset based on your configuration. This is accomplished by writing ones to the appropriate bits in the FPGAPORTRST register in the SDRAM Controller control group.
        - The current bootlaoder build flow is that everything is built into u-boot.
          BSP handoff (more on that later) is configured through header files that are generated by Quartus (as described in `u-boot-socfpga/doc/README.socfpga` in the "Generate BSP handoff files" section).
          A preset version for common boards is also provided directly in tree in `u-boot-socfpga/board/terasic/de10-nano/qts` (this is what we will use / base off).
        - When we build u-boot with SPL the board will run SPL initialization steps first and then hand off to uboot. 
        ```
          +--------+----------------+----------------+----------+
          | Boot   | Terminology #1 | Terminology #2 | Actual   |
          | stage  |                |                | program  |
          | number |                |                | name     |
          +--------+----------------+----------------+----------+
          | 1      |  Primary       |  -             | ROM code |
          |        |  Program       |                |          |
          |        |  Loader        |                |          |
          |        |                |                |          |
          | 2      |  Secondary     |  1st stage     | u-boot   |
          |        |  Program       |  bootloader    | SPL      |
          |        |  Loader (SPL)  |                |          |
          |        |                |                |          |
          | 3      |  -             |  2nd stage     | u-boot   |
          |        |                |  bootloader    |          |
          |        |                |                |          |
          | 4      |  -             |  -             | kernel   |
          |        |                |                |          |
          +--------+----------------+----------------+----------+
        ```
        - The u-boot SPL will initialize a bunch of registers using the handoff configuration files just mentioned, before handing off to u-boot and then to Linux.
          - `sdram_mmr_init_full` will store the `fpgaportrst` (variable is called `fpgaport_rst`) into handoff register 3. These are 8 registers in the sysmanager device that can be used as scratch area for handoff.
          - Default configuration has the reset register at `0x1FF`.
          - The register contents are described in: https://www.intel.com/content/www/us/en/programmable/hps/cyclone-v/hps.html#sfo1411577376106.html
          - The ports that need to be enabled depend on the SDRAM bus configuration (done in Platform Designer under HPS -> FPGA to HPS SDRAM interface).
          - The configuration is documented in `FPGA-to-HPS SDRAM Interface` in the Reference Manual Section 12.5.
          - For Avalon-MM 256 bit read/write we need just `0x1FF` (4 read ports, 4 write ports, 1 control port) so the default configuration is just fine.
          - SDRAM controlller can be configured also to select priorities and weights for configuring scheduling (currently using DE10 nano defaults here as well).

        - To realize the SDRAM boot sequence we need to use the following uboot script commands:
          - `fpga load ...`: does step 1 and 2 (see `socfpga_load` in `u-boot-socfpga/arch/arm/mach-socfpga/system_manager_gen5.c`)
          - `bridge enable ...`: does step 4 and 3 (in this order, not sure yet if this is ok or not). But it only does it if handoff register 3 was non-zero.

      - FPGA Steps:
        - Create custom component in platform designer
        - Add component and wire it to clock, reset, master, trigger and data
        - Implement Avalon state machines for read and write operations in verilog
      - Driver:
        - TODO: check how to do DMA properly (alloc buffers, set addresses, flush / invalidate caches)
      - Register device / driver in u-boot
  
FPGA:
- [x] Add custom LED design to control 8 LEDs
- [x] LED 0 is following clock, change to follow value written by HPS
- [x] Device tree
  - [x] Try to make an LED controller with syscon + led -> does
  - [x] Make my own driver for it instead
- [x] Continue following tutorials
  - [x] kernel module
  - [x] interrupts: compare with ghrd to try and understand what we are missing for the interrupt
                    to be triggered. From devicetree / kernel module side i think we are good
        - ensure bus writes go through avalon adapter (maybe was not working before due to wrong bus?)
        - ensure irq masks are enabled and irqs are cleared after handling
- [ ] Explore CD samples, project structure and source
- [ ] Explore Ethernet MACs and their drivers

Issues:
[x] our kernel is panicing on boot, could be an incompatibility between device tree and kernel version, we could add some logs to kernel or check crash addr -> wrong device tree
[x] currently we have only the devkit in the device tree. Likely want some kind of overlay / override depending on FPGA design, but what the tool generates seems to be off -> now using full custom dtb
[x] uboot does not have ethaddr set in env, figure out best way to add it
[x] uboot not doing anything on boot and just drops into sheel, we would expect it to first run the script and then boot, figure out why.


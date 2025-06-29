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
  - [ ] dma
- [ ] Explore CD samples, project structure and source

Issues:
[x] our kernel is panicing on boot, could be an incompatibility between device tree and kernel version, we could add some logs to kernel or check crash addr -> wrong device tree
[x] currently we have only the devkit in the device tree. Likely want some kind of overlay / override depending on FPGA design, but what the tool generates seems to be off -> now using full custom dtb
[x] uboot does not have ethaddr set in env, figure out best way to add it
[x] uboot not doing anything on boot and just drops into sheel, we would expect it to first run the script and then boot, figure out why.


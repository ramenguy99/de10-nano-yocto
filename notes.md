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
        - [ ] override WKS_FILE

Issues:
[x] our kernel is panicing on boot, could be an incompatibility between device tree and kernel version, we could add some logs to kernel or check crash addr -> wrong device tree
  [ ] currently we have only the devkit in the device tree. Likely want some kind of overlay / override depending on FPGA design, but what the tool generates seems to be off.

- uboot does not have ethaddr set in env, figure out best way to add it
- uboot not doing anything on boot and just drops into sheel, we would expect it to first run the script and then boot, figure out why.
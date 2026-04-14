######################
####  buildroot  #####
######################
.PHONY: buildroot/qemu/build
buildroot/qemu/build:
	@ git clone https://github.com/buildroot/buildroot.git buildroot_qemu
	@ cd buildroot_qemu && git checkout 56c6862bc81ef41c0fe012677eafa24381b1f76c
	@ cd buildroot_qemu && make qemu_riscv64_virt_defconfig
	@ cd buildroot_qemu && sed -i 's/^BR2_TARGET_ROOTFS_EXT2_2=y/# BR2_TARGET_ROOTFS_EXT2_2 is not set/' .config
	@ cd buildroot_qemu && sed -i 's/.*BR2_TARGET_ROOTFS_EXT2_4.*/BR2_TARGET_ROOTFS_EXT2_4=y/' .config
	@ cd buildroot_qemu && make olddefconfig
	@ cd buildroot_qemu && make -j$(shell nproc)

.PHONY: buildroot/gem5/build
buildroot/gem5/build:
	@ git clone git@github.com:buildroot/buildroot.git buildroot_gem5
	@ cd buildroot_gem5 && git checkout 56c6862bc81ef41c0fe012677eafa24381b1f76c
	@ cd buildroot_gem5 && make qemu_riscv64_virt_defconfig
	@ cd buildroot_gem5 && sed -i 's/^BR2_TARGET_ROOTFS_EXT2_2=y/# BR2_TARGET_ROOTFS_EXT2_2 is not set/' .config
	@ cd buildroot_gem5 && sed -i 's/.*BR2_TARGET_ROOTFS_EXT2_4.*/BR2_TARGET_ROOTFS_EXT2_4=y/' .config
	@ cd buildroot_gem5 && make olddefconfig
	@ cd buildroot_gem5 && make -j$(shell nproc)
	@ cd buildroot_gem5 && sed -i 's/^auto eth0/#auto eth0/' output/target/etc/network/interfaces
	@ cd buildroot_gem5 && make -j$(shell nproc)

#########################
####  linux kernel  #####
#########################
.PHONY: linux/qemu/build
linux/qemu/build:
	@ git clone --depth 1 -b v6.8 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux_qemu
	@ cd linux_qemu && make ARCH=riscv CROSS_COMPILE=$(realpath ./buildroot_qemu/output/host/bin)/riscv64-buildroot-linux-gnu- defconfig
	@ cd linux_qemu && make ARCH=riscv CROSS_COMPILE=$(realpath ./buildroot_qemu/output/host/bin)/riscv64-buildroot-linux-gnu- vmlinux Image -j$(shell nproc)

.PHONY: linux/gem5/build
linux/gem5/build:
	@ git clone --depth 1 -b v6.8 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux_gem5
	@ cd linux_gem5 && make ARCH=riscv CROSS_COMPILE=$(realpath ./buildroot_gem5/output/host/bin)/riscv64-buildroot-linux-gnu- defconfig
	@ cd linux_gem5 && make ARCH=riscv CROSS_COMPILE=$(realpath ./buildroot_gem5/output/host/bin)/riscv64-buildroot-linux-gnu- vmlinux Image -j$(shell nproc)

###########################
########  OpenSBI  ########
###########################
.PHONY: opensbi/qemu/build
opensbi/qemu/build:
	@ git clone https://github.com/riscv-software-src/opensbi.git opensbi_qemu
	@ cd opensbi_qemu && git checkout 0b041e58c0787f76325da5081e41a13bf304d328
	@ cd opensbi_qemu && make CROSS_COMPILE=$(realpath ./buildroot_qemu/output/host/bin)/riscv64-buildroot-linux-gnu- PLATFORM=generic  FW_TEXT_START=0x80000000 -j$(shell nproc)

# We need to build linux kernel before building OpenSBI when we use gem5
.PHONY: opensbi/gem5/build
opensbi/gem5/build:
	@ git clone https://github.com/riscv-software-src/opensbi.git opensbi_gem5
	@ cd opensbi_gem5 && git checkout 0b041e58c0787f76325da5081e41a13bf304d328
	@ cd opensbi_gem5 && make CROSS_COMPILE=$(realpath ./buildroot_gem5/output/host/bin)/riscv64-buildroot-linux-gnu- PLATFORM=generic FW_PAYLOAD_PATH=$(realpath ./linux_gem5/arch/riscv/boot/Image) -j$(shell nproc)

##############################
######### xv6-riscv ##########
##############################
.PHONY: xv6-riscv/clone
xv6-riscv/clone:
	@ git clone -b gem5-xv6-riscv https://github.com/TommyWu-fdgkhdkgh/xv6-riscv.git

.PHONY: xv6-riscv/build/SV39
xv6-riscv/build/SV39:
	@ make -C ./xv6-riscv clean && make -C ./xv6-riscv VM_MODE=SV39 kernel/kernel fs.img

.PHONY: xv6-riscv/build/SV48
xv6-riscv/build/SV48:
	@ make -C ./xv6-riscv clean && make -C ./xv6-riscv VM_MODE=SV48 kernel/kernel fs.img

.PHONY: xv6-riscv/build/SV57
xv6-riscv/build/SV57:
	@ make -C ./xv6-riscv clean && make -C ./xv6-riscv VM_MODE=SV57 kernel/kernel fs.img

#########################
######### QEMU ##########
#########################
.PHONY: qemu/build
qemu/build:
	@ git clone git@github.com:qemu/qemu.git
	@ cd qemu && git checkout v10.0.0
	@ cd qemu && python -m venv ./my-venv
	@ cd qemu && source ./my-venv/bin/activate && \
		pip install --upgrade setuptools && \
		pip install --upgrade distlib && \
		./configure --target-list=riscv64-softmmu && \
		make -j$(nproc)

.PHONY: qemu/run/xv6-riscv/SV39
qemu/run/xv6-riscv/SV39:
	@ export PATH=$(PATH):$(PWD)/qemu/build && \
          make -C ./xv6-riscv/ clean && make -C ./xv6-riscv/ VM_MODE=SV39 qemu

.PHONY: qemu/run/xv6-riscv/SV48
qemu/run/xv6-riscv/SV48:
	@ export PATH=$(PATH):$(PWD)/qemu/build && \
          make -C ./xv6-riscv/ clean && make -C ./xv6-riscv/ VM_MODE=SV48 qemu

.PHONY: qemu/run/xv6-riscv/SV57
qemu/run/xv6-riscv/SV57:
	@ export PATH=$(PATH):$(PWD)/qemu/build && \
          make -C ./xv6-riscv/ clean && make -C ./xv6-riscv/ VM_MODE=SV57 qemu

.PHONY: qemu/run/linux/SV39
qemu/run/linux/SV39:
	@ $(PWD)/qemu/build/qemu-system-riscv64 \
     -M virt \
     -smp 3 \
     -bios $(PWD)/opensbi_qemu/build/platform/generic/firmware/fw_jump.elf \
     -kernel $(PWD)/linux_qemu/arch/riscv/boot/Image \
     -append "root=/dev/vda ro console=ttyS0 no4lvl" \
     -drive file=$(PWD)/buildroot_qemu/output/images/rootfs.ext4,format=raw,id=hd0,if=none \
     -device virtio-blk-device,drive=hd0 \
     -netdev user,id=net0 \
     -device virtio-net-device,netdev=net0 \
     -nographic

.PHONY: qemu/run/linux/SV48
qemu/run/linux/SV48:
	@ $(PWD)/qemu/build/qemu-system-riscv64 \
     -M virt \
     -smp 3 \
     -bios $(PWD)/opensbi_qemu/build/platform/generic/firmware/fw_jump.elf \
     -kernel $(PWD)/linux_qemu/arch/riscv/boot/Image \
     -append "root=/dev/vda ro console=ttyS0 no5lvl" \
     -drive file=$(PWD)/buildroot_qemu/output/images/rootfs.ext4,format=raw,id=hd0,if=none \
     -device virtio-blk-device,drive=hd0 \
     -netdev user,id=net0 \
     -device virtio-net-device,netdev=net0 \
     -nographic

.PHONY: qemu/run/linux/SV57
qemu/run/linux/SV57:
	@ $(PWD)/qemu/build/qemu-system-riscv64 \
     -M virt \
     -smp 3 \
     -bios $(PWD)/opensbi_qemu/build/platform/generic/firmware/fw_jump.elf \
     -kernel $(PWD)/linux_qemu/arch/riscv/boot/Image \
     -append "root=/dev/vda ro console=ttyS0" \
     -drive file=$(PWD)/buildroot_qemu/output/images/rootfs.ext4,format=raw,id=hd0,if=none \
     -device virtio-blk-device,drive=hd0 \
     -netdev user,id=net0 \
     -device virtio-net-device,netdev=net0 \
     -nographic

##########################
#########  gem5 ##########
##########################
.PHONY: gem5/clone
gem5/clone:
	@ git clone -b upstream-vm-mode-2026-04-14 https://github.com/TommyWu-fdgkhdkgh/gem5.git

.PHONY: gem5/build
gem5/build:
	@ cd gem5 && git checkout 7a2b0e413d06c5ce7097104abef3b1d9eaabca91 
	@ cd gem5 && scons build/RISCV/gem5.opt -j$(shell nproc)

.PHONY: gem5/term
gem5/term:
	@ ./gem5/util/term/gem5term 3456

.PHONY: gem5/run/xv6-riscv
gem5/run/xv6-riscv:
	@ ./gem5/build/RISCV/gem5.opt ./run_xv6.py --kernel-type=xv6-riscv

.PHONY: gem5/run/linux/SV39
gem5/run/linux/SV39:
	@ ./gem5/build/RISCV/gem5.opt ./run_xv6.py --kernel-type=linux --vm-mode=sv39

.PHONY: gem5/run/linux/SV48
gem5/run/linux/SV48:
	@ ./gem5/build/RISCV/gem5.opt ./run_xv6.py --kernel-type=linux --vm-mode=sv48

.PHONY: gem5/run/linux/SV57
gem5/run/linux/SV57:
	@ ./gem5/build/RISCV/gem5.opt ./run_xv6.py --kernel-type=linux --vm-mode=sv57

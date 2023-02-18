SHELL := /bin/bash
TOOLS ?= /opt/Xilinx/SDK
VERSION ?= 2019.1
BOARD ?= zed

OPTS = 
ifeq ($(VERSION), )
	OPSS += -version $(VERSION)
endif
ifeq ($(BOARD), )
	OPTS += -board $(BOARD)
endif

get_sources:
	if [ ! -d "./bootgen" ];then \
		git clone https://github.com/Xilinx/bootgen; \
		$(MAKE) -C bootgen; \
		fi
	if [ ! -d "./linux-xlnx" ];then \
		git clone https://github.com/Xilinx/linux-xlnx; \
		cd linux-xlnx && git checkout xilinx-v$(VERSION); \
		fi
	if [ ! -d "./repo" ];then \
		mkdir -p repo/my_dtg; \
		cd repo/my_dtg && git clone https://github.com/Xilinx/device-tree-xlnx; \
		cd device-tree-xlnx && git checkout xilinx-v$(VERSION); \
		fi
	if [ ! -d "./u-boot-xlnx" ];then \
		git clone https://github.com/Xilinx/u-boot-xlnx; \
		cd u-boot-xlnx && git checkout xilinx-v$(VERSION); \
		fi
	if [ ! -d "./arm-trusted-firmware" ];then \
		git clone https://github.com/Xilinx/arm-trusted-firmware; \
		cd arm-trusted-firmware && git checkout xilinx-v$(VERSION); \
		fi
	if [ ! -d "./dtc" ];then \
		git clone https://git.kernel.org/pub/scm/utils/dtc/dtc.git; \
		$(MAKE) -C dtc; \
		fi
	if [ ! -d "./embeddedsw" ];then \
		git clone https://github.com/Xilinx/embeddedsw; \
		cd embeddedsw && git checkout xilinx-v$(VERSION); \
		fi

init_repos:
	git submodule update --init --recursive

prepare_sources:
	$(MAKE) -C bootgen -j16
	$(MAKE) -C dtc -j16
	cd linux-xlnx && git checkout xilinx-v$(VERSION)
	cd repo/my_dtg/device-tree-xlnx && git checkout xilinx-v$(VERSION)
	cd u-boot-xlnx && git checkout xilinx-v$(VERSION)
	cd arm-trusted-firmware && git checkout xilinx-v$(VERSION)
	cd embeddedsw && git checkout xilinx-v$(VERSION)

fsbl:
	$(RM) -r zynq_fsbl
	echo "build_fsbl -version $(VERSION)" | $(TOOLS)/$(VERSION)/bin/hsi -source script.tcl -nojournal -nolog -tempDir ./tmp

# Refer to https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841973/Build+U-Boot
# For Zynq:
#     export CROSS_COMPILE=arm-linux-gnueabihf-
#     export ARCH=arm
# For ZynqUS+:
#     export CROSS_COMPILE=aarch64-linux-gnu-
#     export ARCH=aarch64
# For uboot < 2020.1 
#     make <board_defconfig> (here, zynq_zed_defconfig)
# For uboot > 2020.1 
# 	  make xilinx_zynq[mp]_virt_defconfig
build_uboot:
	$(MAKE) -C u-boot-xlnx clean
	source $(TOOLS)/$(VERSION)/settings64.sh; \
		export CROSS_COMPILE=arm-linux-gnueabihf-; \
		export ARCH=arm; \
		export PATH=$$PATH:$(shell pwd)/dtc; \
		cd u-boot-xlnx; \
		$(MAKE) zynq_zed_defconfig; \
		$(MAKE) -f Makefile all -j16

build_kernel:
	$(MAKE) -C linux-xlnx clean
	# Is UIMAGE_LOADADDR optional? 
	source $(TOOLS)/$(VERSION)/settings64.sh; \
		export CROSS_COMPILE=arm-linux-gnueabihf-; \
		export ARCH=arm; \
		export UIMAGE_LOADADDR=0x8000; \
		cd linux-xlnx; \
		$(MAKE) -f Makefile xilinx_zynq_defconfig; \
		$(MAKE) -f Makefile all -j16

build_dts:
	$(RM) -r my_dts
	# echo "build_dts -version $(VERSION) -board $(BOARD)" | $(TOOLS)/$(VERSION)/bin/hsi -source script.tcl -nojournal -nolog
	echo "build_dts -version $(VERSION)" | $(TOOLS)/$(VERSION)/bin/hsi -source script.tcl -nojournal -nolog -tempDir ./tmp

build_dtb:
	$(RM) -r system.dtb
	export PATH=$$PATH:$(shell pwd)/dtc; \
		gcc -I my_dts -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o my_dts/system-top.dts.tmp my_dts/system-top.dts; \
		dtc -I dts -O dtb -o system.dtb my_dts/system-top.dts.tmp

extract_rootfs: # This is from release
	tar xvf $(VERSION)-$(BOARD)-release.tar.xz
	./u-boot-xlnx/tools/dumpimage -i $(VERSION)-$(BOARD)-release/image.ub -T flat_dt -p 2 rootfs.cpio.gz

bootimage:
	export PATH=$$PATH:$(shell pwd)/bootgen; \
		bootgen -arch zynq -image bootgen.bif -w -o BOOT.BIN

fit_image:
	export PATH=$$PATH:$(shell pwd)/dtc; \
		./u-boot-xlnx/tools/mkimage -f fitimage.its image.ub


clean_tmp:
	-rm -rf ps* 

SHELL := /bin/bash
TOOLS ?= /opt/Xilinx/SDK
VERSION ?= 2019.1
BOARD ?= 

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

build_dts:
	$(RM) -r my_dts
	# echo "build_dts -version $(VERSION) -board $(BOARD)" | $(TOOLS)/$(VERSION)/bin/hsi -source script.tcl -nojournal -nolog
	echo "build_dts -version $(VERSION)" | $(TOOLS)/$(VERSION)/bin/hsi -source script.tcl -nojournal -nolog -tempDir ./tmp

clean_tmp:
	-rm -rf ps* 

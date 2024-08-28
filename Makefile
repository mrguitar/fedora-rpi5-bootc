SHELL := /bin/bash

#Inspired by the excellent work here: https://github.com/containers/ai-lab-recipes/blob/main/recipes/common/Makefile.common

RELEASE ?= 40
USR ?= core
REGISTRY ?= quay.io
REGISTRY_ORG ?= 
ROOTFS ?= ext4
IMAGE ?= fedora-rpi5-bootc:latest
SSH_PUBKEY ?= $(shell cat ${HOME}/.ssh/id_rsa.pub;)
BOOTC_IMAGE ?= $(REGISTRY)/$(REGISTRY_ORG)/${IMAGE}
BOOTC_IMAGE_BUILDER ?= quay.io/centos-bootc/bootc-image-builder
DISK_TYPE ?= raw
DISK_UID ?= $(shell id -u)
DISK_GID ?= $(shell id -g)
FROM ?= quay.io/fedora/fedora-bootc:latest
ARCH ?= arm64
BUILD_ARG_FILE ?=
CONTAINERFILE ?= Containerfile
GRAPH_ROOT=$(shell podman info --format '{{ .Store.GraphRoot }}')
UMASK=$(shell umask)
FETCHFW=bash -c 'mkdir -p /tmp/efi/boot/efi && dnf install -y --downloadonly --release=${RELEASE} --forcearch=aarch64 --destdir=/tmp/efi/ uboot-images-armv8 bcm283x-firmware bcm283x-overlays && for rpm in /tmp/efi/*rpm; do rpm2cpio $rpm | cpio -idv -D /tmp/efi/; done && mv /tmp/efi/usr/share/uboot/rpi_arm64/u-boot.bin /tmp/efi/boot/efi/rpi-u-boot.bin'

ROOTLESS_AUTH_JSON=${XDG_RUNTIME_DIR}/containers/auth.json
ROOTFUL_AUTH_JSON=/run/containers/0/auth.json
NONLINUX_AUTH_JSON=${HOME}/.config/containers/auth.json
AUTH_JSON ?=

ifneq ("$(wildcard $(NONLINUX_AUTH_JSON))","")
	AUTH_JSON=$(NONLINUX_AUTH_JSON)
else ifneq ("$(wildcard $(ROOTLESS_AUTH_JSON))","")
	AUTH_JSON=$(ROOTLESS_AUTH_JSON)
else ifneq ("$(wildcard $(ROOTFUL_AUTH_JSON))","")
	AUTH_JSON=$(ROOTFUL_AUTH_JSON)
endif

OS := $(shell uname -s)

#We always want to Target arm64 for this work
#ARCH := $(shell uname -m)
#ifeq ($(ARCH),x86_64)
#	ARCH := amd64
#endif

.PHONY: bootc
bootc: 
	podman build \
	  $(ARCH:%=--arch %) \
	  $(FROM:%=--from %) \
	  $(AUTH_JSON:%=-v %:/run/containers/0/auth.json) \
	  --security-opt label=disable \
	  --cap-add SYS_ADMIN \
	  --build-arg "SSHPUBKEY=$(SSH_PUBKEY)" \
	  --build-arg "USER=$(USR)" \
	  -f $(CONTAINERFILE) \
	  -t ${BOOTC_IMAGE} .
	@echo ""
	@echo "Successfully built bootc image '${BOOTC_IMAGE}'."
	@echo "You may now convert the image into a disk image via bootc-image-builder"
	@echo "or the Podman Desktop Bootc Extension.  For more information, please refer to"
	@echo "   * https://github.com/osbuild/bootc-image-builder"
	@echo "   * https://github.com/containers/podman-desktop-extension-bootc"

.PHONY: image
image:
	@if podman image exists $(BOOTC_IMAGE); then \
		echo "$(BOOTC_IMAGE) exists in local storage, using it"; \
	else \
		$(MAKE) bootc; \
	fi
	mkdir -p build/store
	podman run \
	  --rm \
	  -ti \
	  -v $(GRAPH_ROOT):/var/lib/containers/storage \
	  $(ARCH:%=--arch %) \
	  $(AUTH_JSON:%=-v %:/run/containers/0/auth.json) \
	  --privileged \
	  --pull newer \
	  -v ./build:/output \
	  $(BOOTC_IMAGE_BUILDER) \
	  $(ARCH:%=--target-arch %) \
	  --type $(DISK_TYPE) \
	  --chown $(DISK_UID):$(DISK_GID) \
	  --local \
	  --rootfs ${ROOTFS} \
	  $(BOOTC_IMAGE)


.PHONY: dl-fw
dl-fw:
	#This script runs great when executed as described here: https://mrguitar.net/?p=2605 For some reason it doesn't seem to be able to write to tmp.
	podman run -ti --rm -v tmp:/tmp quay.io/fedora/fedora-bootc $(FETCHFW)


#.PHONY: firmware-load:
#firmware-load:
	#No clue how to mount the raw image and copy over the firmware - should be doable

#.PHONY: growfs

#Ideally here we could resize the image for the SD card.
#growfs: quadlet check-umask
#	# Add growfs service
#	mkdir -p build; cp -pR ../../common/usr build/

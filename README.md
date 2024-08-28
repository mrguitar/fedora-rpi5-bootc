# fedora-rpi5-bootc
Create a Fedora bootable container for the Raspberry Pi 5

# :construction: This repo is does not yet yeild a working image. :construction:

Getting fedora-bootc to work on the RPi4 is super easy and straightforward. [This blog](https://mrguitar.net/?p=2605) will walk you through it. As the RPi5 isn't officially supported in Fedora, it's a bit more complicated to make things work. Luckily, downstream kernels are built [here](https://download.copr.fedorainfracloud.org/results/dwrobel/kernel-rpi/fedora-40-aarch64/) and we just need to figure out how to add the firmware and have the system boot the proper kernel that bootc is installing. By default the cmdline.txt file will point to /efi/kernel8.img and we need to tweak this. 

## Usage
1. Clone the repo
2. Edit the Containerfile & Makefile to meet your needs.
3. run `make bootc` to create the container image
4. run `make image` to create a raw image


## To Do:
- Figure out how the [premade images] (https://rpmfusion.org/Howto/RaspberryPi) are booting and how to recreate that in a bootc environment
- Complete firmware sections of the Makefile
- Create a `make all` (or similar) to create a fully fuctional image ready to dd to an SD card
- Document resizing the image / filesystem

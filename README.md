# fedora-rpi5-bootc
Create a Fedora bootable container for the Raspberry Pi 5


##Usage
1. Clone the repo
2. Edit the Containerfile & Makefile to meet your needs.
3. run <make bootc> to create the container image
4. run <make image> to create a raw image


To Do:
- Figure out how the [premade images] (https://rpmfusion.org/Howto/RaspberryPi) are booting and how to recreate that in a bootc environment
- Complete firmware sections of the Makefile
- Create a make all (or similar)
- Document resizing the image / filesystem

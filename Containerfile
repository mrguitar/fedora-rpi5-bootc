FROM quay.io/fedora/fedora-bootc:latest
ARG SSHPUBKEY
ARG USER

#remove original kernel & clean up the initrd
RUN export DEFAULT_KERNEL=$(rpm --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}" -q kernel) && RM_KERNEL=$DEFAULT_KERNEL && rpm -e kernel{,-core,-modules,-modules-core} && rm -rf /usr/lib/modules/$RM_KERNEL

# Enable repos for rpi kernel and firmware
RUN dnf install -y dnf5-plugins && dnf copr enable -y dwrobel/kernel-rpi &&  dnf copr enable -y dwrobel/bcm434xx-firmware-rpi  && dnf copr enable -y dwrobel/bcm283x-firmware-rpi 

# Change priority of rpi kernel repo
RUN dnf config-manager setopt "copr:copr.fedorainfracloud.org:dwrobel:kernel-rpi.priority=50"
# Install rpi4 kernel and firmware
RUN dnf install -y kernel-rpi4-modules-extra kernel-rpi4 kernel-rpi4-modules-extra bcm283x-firmware bcm434xx-firmware 

#let's make a new initrd - your computer will thank you by booting now!
RUN export RPI_KERNEL=$(rpm --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}" -q kernel-rpi4) && dracut -vf /usr/lib/modules/$RPI_KERNEL/initramfs.img $RPI_KERNEL

#add your desired packages; this is a decent starting point:
RUN dnf -y install cockpit cockpit-ws cockpit-podman git tree wireless-regdb wpa_supplicant NetworkManager-wifi vim-enhanced && dnf clean all && systemctl enable cockpit.socket 
COPY etc etc

ARG SSHPUBKEY
# We don't yet ship a one-invocation CLI command to add a user with a SSH key unfortunately
RUN if test -z "$SSHPUBKEY"; then echo "must provide SSHPUBKEY"; exit 1; fi; \
    useradd -G wheel $USER && \
    mkdir -m 0700 -p /home/$USER/.ssh && \
    echo $SSHPUBKEY > /home/$USER/.ssh/authorized_keys && \
    chmod 0600 /home/$USER/.ssh/authorized_keys && \
    chown -R $USER: /home/$USER

RUN set -eu; mkdir -p /usr/ssh && \
    echo 'AuthorizedKeysFile /usr/ssh/%u.keys .ssh/authorized_keys .ssh/authorized_keys2' >> /etc/ssh/sshd_config.d/30-auth-system.conf && \
    echo ${SSHPUBKEY} > /usr/ssh/root.keys && chmod 0600 /usr/ssh/root.keys


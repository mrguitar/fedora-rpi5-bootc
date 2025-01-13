FROM quay.io/fedora/fedora-bootc:latest
ARG SSHPUBKEY
ARG USER

#add your desired packages; this is a decent starting point:
RUN dnf -y install cockpit cockpit-ws cockpit-podman git tree wireless-regdb wpa_supplicant NetworkManager-wifi && dnf clean all && systemctl enable cockpit.socket #vim-enhanced
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

# Enable repos for rpi kernel and firmwar
RUN dnf copr enable -y dwrobel/kernel-rpi &&  dnf copr enable -y dwrobel/bcm434xx-firmware-rpi  && dnf copr enable -y dwrobel/bcm283x-firmware-rpi 

# Change priority of rpi kernel repo
RUN dnf config-manager setopt "copr:copr.fedorainfracloud.org:dwrobel:kernel-rpi.priority=50"

# Downgrade kernel to install rpi kernel
RUN dnf downgrade kernel -y

# Install rpi4 kernel and firmware
RUN dnf install -y kernel-modules-extra kernel-rpi4 kernel-rpi4-modules-extra bcm283x-firmware bcm434xx-firmware && dnf clean all

#delete the prior initrd
RUN rm -rdf /usr/lib/modules/6.10*

#let's make a new initrd - your computer will thank you by booting now!
RUN dracut -vf /usr/lib/modules/6.6.42-1.rpi4.fc40.aarch64/initramfs.img 6.6.42-1.rpi4.fc40.aarch64

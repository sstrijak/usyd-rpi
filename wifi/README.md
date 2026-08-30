Full guide available from http://wiki.zde.plus/ZP585

1. Check the card is installed
$ lspci
0001:00:00.0 PCI bridge: Broadcom Inc. and subsidiaries BCM2712 PCIe Bridge (rev 30)
0001:01:00.0 Network controller: Intel Corporation Wi-Fi 6E(802.11ax) AX210/AX1675* 2x2 [Typhoon Peak] (rev 1a)           << This is our card
0002:00:00.0 PCI bridge: Broadcom Inc. and subsidiaries BCM2712 PCIe Bridge (rev 30)
0002:01:00.0 Ethernet controller: Raspberry Pi Ltd RP1 PCIe 2.0 South Bridge

2. Update the system and Install kernel header file:
sudo apt update
sudo apt install linux-headers-$(uname -r) firmware-iwlwifi flex bison

3. Download the AX210 firmware

# 1. Download iwlwifi-ty-a0-gf-a0-89.ucode
sudo wget -O /lib/firmware/iwlwifi-ty-a0-gf-a0-89.ucode https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/intel/iwlwifi/iwlwifi-ty-a0-gf-a0-89.ucode

# If the git.kernel.org path fails, grab it from the Armbian mirror:
# sudo wget -O /lib/firmware/iwlwifi-ty-a0-gf-a0-89.ucode \
#   https://raw.githubusercontent.com/armbian/firmware/master/iwlwifi-ty-a0-gf-a0-89.ucode

# 2. Download the matching PNVM file
sudo wget -O /lib/firmware/iwlwifi-ty-a0-gf-a0.pnvm https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/intel/iwlwifi/iwlwifi-ty-a0-gf-a0.pnvm

sudo mkdir -p /lib/firmware/intel
sudo cp /lib/firmware/iwlwifi-ty-a0-gf-a0-89.ucode /lib/firmware/intel/
sudo cp /lib/firmware/iwlwifi-ty-a0-gf-a0.pnvm /lib/firmware/intel/

4. (Re)Load the driver
sudo modprobe -r iwlwifi iwlwifi
sudo modprobe iwlwifi

5. Check that driver is loaded
dmesg | grep -i iwl
ip link show

ict@ict-comms-rpi-8gb:~/usyd-rpi/wifi/iwlwifi/iwlwifi $ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 98:fe:54:05:4c:37 brd ff:ff:ff:ff:ff:ff
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DORMANT group default qlen 1000
    link/ether 98:fe:54:05:4c:38 brd ff:ff:ff:ff:ff:ff
4: wlan1: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DORMANT group default qlen 1000
    link/ether 20:bd:1d:d4:d0:3c brd ff:ff:ff:ff:ff:ff





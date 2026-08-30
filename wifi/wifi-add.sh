#!/usr/bin/env bash

# Initialize variables (no spaces around '=')
mode=""
interface=""
ssid=""
username=""
password=""

# Print usage function
print_usage() {
    echo "Usage: $0 interface=<interface> mode=<mode> ssid=<ssid> [username=<username>] [password=<password>]"
    echo "  interface: run 'iw dev' command to list available interfaces"
    echo "  mode: 802.1x (requires username and password) or PSK"
    echo "Example: $0 interface=wlan0 mode=802.1x ssid=home username=me password=pswd"
    echo "Example: $0 interface=wlan0 mode=PSK ssid=home password=pswd"
    exit 1
}

# Parse key=value arguments regardless of order
for arg in "$@"; do
    case "$arg" in
        interface=*)
            interface="${arg#interface=}"
            ;;
        mode=*)
            mode="${arg#mode=}"
            ;;
        ssid=*)
            ssid="${arg#ssid=}"
            ;;
        username=*)
            username="${arg#username=}"
            ;;
        password=*)
            password="${arg#password=}"
            ;;
        *)
            echo "Unknown parameter: $arg"
            print_usage
            ;;
    esac
done

# Validate common required parameters
if [[ -z "$interface" || -z "$mode" || -z "$ssid" ]]; then
    echo "Error: Missing required parameters (interface, mode, ssid)."
    print_usage
fi

# Create the connection based on mode
if [[ "$mode" == "802.1x" ]]; then
    if [[ -z "$username" || -z "$password" ]]; then
        echo "Error: 802.1x mode requires both username and password."
        print_usage
    fi

    echo "Configuring 802.1x enterprise mode..."
    sudo nmcli connection add type wifi con-name "${interface}_${ssid}_${username}" ifname "$interface" ssid "$ssid" \
        wifi-sec.key-mgmt wpa-eap \
        802-1x.eap peap \
        802-1x.phase2-auth mschapv2 \
        802-1x.identity "$username" \
        802-1x.password "$password"

elif [[ "$mode" == "PSK" ]]; then
    echo "Configuring WPA-PSK mode..."
    if [[ -z "$password" ]]; then
        # Open network / unencrypted
        sudo nmcli connection add type wifi con-name "${interface}_$ssid" ifname "$interface" ssid "$ssid"
    else
        # PSK encrypted network
        sudo nmcli connection add type wifi con-name "${interface}_$ssid" ifname "$interface" ssid "$ssid" \
            wifi-sec.key-mgmt wpa-psk \
            wifi-sec.psk "$password"
    fi

else
    echo "Invalid mode: $mode"
    print_usage
fi

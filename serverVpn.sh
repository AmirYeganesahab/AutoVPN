#!/bin/bash

# Update package lists
sudo apt-get update

# Install OpenVPN
if ! command -v openvpn &> /dev/null
then
    sudo apt-get install -y openvpn
    echo "OpenVPN installed successfully."
else
    echo "OpenVPN is already installed."
fi

# Install Easy-RSA
if ! command -v easyrsa &> /dev/null
then
    sudo apt-get install -y easy-rsa
    echo "Easy-RSA installed successfully."
else
    echo "Easy-RSA is already installed."
fi


#!/bin/bash

# Make a new directory for your CA
make-cadir ~/openvpn-ca

# Navigate to the new directory
cd ~/openvpn-ca

# Edit the vars file to set the KEY_NAME variable to openvpn-ca
sed -i 's/KEY_NAME="EasyRSA"/KEY_NAME="openvpn-ca"/' vars

# Initialize the PKI (Public Key Infrastructure)
./easyrsa init-pki

# Build the CA, set the common name to openvpn-ca
./easyrsa build-ca


# Generate a key pair and sign the certificate for the server
./easyrsa gen-req vpnserver nopass
./easyrsa sign-req server vpnserver

# Generate a key pair and sign the certificate for the client
./easyrsa gen-req vpnclient nopass
./easyrsa sign-req client vpnclient

# Generate Diffie-Hellman parameters
./easyrsa gen-dh


# Generate the TLS authentication key
openvpn --genkey secret ta.key

# Ask the operator for their preference
echo "Do you want to share the files via human interface or via IP transfer? (Enter 'human' or 'ip')"
read transfer_method

if [ "$transfer_method" = "human" ]
then
    echo "Please share the files manually and press any key to continue..."
    read -n 1 -s
else
    echo "Please enter the username and IP address of the client PC (format: username@ip):"
    read client_details
    # Copy the necessary files to the client PC
    scp pki/ca.crt $client_details:/home/cloud_user/
    scp pki/issued/vpnclient.crt $client_details:/home/cloud_user/
    scp pki/private/vpnclient.key $client_details:/home/cloud_user/
    scp ta.key $client_details:/home/cloud_user/
fi

# Check if the file exists
if [ -f "/usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz" ]
then
    # Decompress the file
    gzip -d /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz

    # Copy the file to the desired location
    sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/vpnserver.conf
else
    echo "File does not exist [/usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz]."
fi

# Define the path to the files
path_to_files="/etc/openvpn"

# Modify vpnserver.conf to correctly point to the files
sudo sed -i "s|ca .*|ca $path_to_files/ca.crt|" /etc/openvpn/vpnserver.conf
sudo sed -i "s|cert .*|cert $path_to_files/vpnserver.crt|" /etc/openvpn/vpnserver.conf
sudo sed -i "s|key .*|key $path_to_files/vpnserver.key|" /etc/openvpn/vpnserver.conf
sudo sed -i "s|dh .*|dh $path_to_files/dh.pem|" /etc/openvpn/vpnserver.conf

# Enable IPv4 forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Make the change permanent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf


# Start the OpenVPN service
sudo systemctl start openvpn@server

# Enable the OpenVPN service to start on boot
sudo systemctl enable openvpn@server

# Print the status of the OpenVPN service
sudo systemctl status openvpn@server

# Print a message about sharing the client configuration file and certificates
echo "Please make sure you share the client configuration file and certificates with the client. They are located in /etc/openvpn."

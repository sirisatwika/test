az login --tenant df7b3572-e484-4fcf-a072-6edd5d73f11f
cert_name = testg
cert_path = test
key_vault_name = certutilitykeyvault2
upload_certificate_to_keyvault() {
 local cert_name=$1
 local cert_path=$2
 az keyvault certificate import --name "$cert_name" --vault-name "$key_vault_name" --file "$cert_path"
}
# Main script execution
read -p "Enter the prefix for the certificates: " cert_prefix
read -p "Enter the directory to save the certificates: " cert_dir
# Set the number of certificates to create
num_certs=1  # Change this value as needed
create_certificates "$cert_prefix" "$cert_dir"
# Download and install Microsoft repository configuration
sudo wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb-O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
# Install Moby Engine
sudo apt-get update
sudo apt-get install -y moby-engine
# Configure Docker daemon to use local logging driver
echo "{
 \"log-driver\": \"local\"
}" | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
# Install Azure IoT Edge
sudo apt-get update
sudo apt-get install -y aziot-edge
# Configure Azure IoT Edge
sudo cp /etc/aziot/config.toml.edge.template /etc/aziot/config.toml
# Uncomment specific lines by line numbers
sudo sed -i '172s/^#//' /etc/aziot/config.toml  # Uncomment [provisioning]
sudo sed -i '173s/^#//' /etc/aziot/config.toml  # Uncomment source = "dps"
sudo sed -i '174s/^#//' /etc/aziot/config.toml  # Uncomment global_endpoint
sudo sed -i '175s/^#//' /etc/aziot/config.toml  # Uncomment id_scope
sudo sed -i '180s/^#//' /etc/aziot/config.toml  # Uncomment [provisioning.attestation]
sudo sed -i '181s/^#//' /etc/aziot/config.toml  # Uncomment method = "x509"
sudo sed -i '182s/^#//' /etc/aziot/config.toml  # Uncomment registration_id
sudo sed -i '185s/^#//' /etc/aziot/config.toml  # Uncomment identity_pk
sudo sed -i '189s/^#//' /etc/aziot/config.toml  # Uncomment identity_pk
# Set provisioning configuration
id_scope="0ne003795A9"
registration_id=${cert_prefix}
DEVICE_IDENTITY_CERTIFICATE=file:///${cert_dir}/${cert_prefix}_1.crt
DEVICE_IDENTITY_PRIVATE_KEY_HERE=file:///${cert_dir}/${cert_prefix}_1.key
# Replace placeholders in the config file
sudo sed -i '175s/.*/id_scope="0ne003795A9"/' /etc/aziot/config.toml
sudo sed -i "182s/.*/registration_id=\"$cert_prefix\"/" /etc/aziot/config.toml
sudo sed -i "189s|.*|identity_cert=\"$DEVICE_IDENTITY_CERTIFICATE\"|" /etc/aziot/config.toml
sudo sed -i "185s|.*|identity_pk=\"$DEVICE_IDENTITY_PRIVATE_KEY_HERE\"|" /etc/aziot/config.toml
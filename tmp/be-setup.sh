#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables - replace these values as needed
DATA_DIR="/data/be"
BE_DIR="/path/to/be/deployment/files" # Update this path to your actual BE deployment directory
BE_PORT="9060"            # replace 'vvvv' with desired BE port
BE_HTTP_PORT="8040"       # replace 'xxxx' with desired BE HTTP port
HEARTBEAT_SERVICE_PORT="9050" # replace 'yyyy' with desired heartbeat service port
BRPC_PORT="8060"          # replace 'zzzz' with desired BRPC port

# Step 1: Create data directory
mkdir -p $DATA_DIR

# Step 2: Modify BE configuration file
BE_CONF="$BE_DIR/be/conf/be.conf"

# Backup the original configuration file
cp $BE_CONF $BE_CONF.bak

# Update storage_root_path in the configuration file
sed -i "s|^storage_root_path=.*|storage_root_path=$DATA_DIR|" $BE_CONF

# Update ports in the configuration file
sed -i "s|^be_port=.*|be_port=$BE_PORT|" $BE_CONF
sed -i "s|^be_http_port=.*|be_http_port=$BE_HTTP_PORT|" $BE_CONF
sed -i "s|^heartbeat_service_port=.*|heartbeat_service_port=$HEARTBEAT_SERVICE_PORT|" $BE_CONF
sed -i "s|^brpc_port=.*|brpc_port=$BRPC_PORT|" $BE_CONF

# Print success message
echo "Configuration updated successfully."
echo "storage_root_path set to $DATA_DIR"
echo "be_port set to $BE_PORT"
echo "be_http_port set to $BE_HTTP_PORT"
echo "heartbeat_service_port set to $HEARTBEAT_SERVICE_PORT"
echo "brpc_port set to $BRPC_PORT"

# Step 3: Create a systemd service file
SERVICE_FILE="/etc/systemd/system/starrocks-be.service"

cat << EOF > $SERVICE_FILE
[Unit]
Description=StarRocks Backend Service
After=network.target

[Service]
Type=forking
User=root
ExecStart=$BE_DIR/be/bin/start_be.sh --daemon
ExecStop=$BE_DIR/be/bin/stop_be.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable starrocks-be
systemctl start starrocks-be

# Verify if the BE node is started successfully
sleep 5  # wait a few seconds for the BE node to start
cat $BE_DIR/be/log/be.out | grep -i "StarRocks Backend" # Check the log for confirmation

echo "BE node started successfully as a systemd service."

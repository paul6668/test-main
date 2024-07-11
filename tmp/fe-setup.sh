#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables - replace these values as needed
META_DIR="/data/fe"
FE_DIR="/path/to/fe/deployment/files" # Update this path to your actual FE deployment directory
HTTP_PORT="8030"    # replace 'aaaa' with desired HTTP port
RPC_PORT="9020"     # replace 'bbbb' with desired RPC port
QUERY_PORT="9030"   # replace 'cccc' with desired query port
EDIT_LOG_PORT="9010" # replace 'dddd' with desired edit log port

# Step 1: Create metadata directory
mkdir -p $META_DIR

# Step 2: Modify FE configuration file
FE_CONF="$FE_DIR/fe/conf/fe.conf"

# Backup the original configuration file
cp $FE_CONF $FE_CONF.bak

# Update meta_dir in the configuration file
sed -i "s|^meta_dir=.*|meta_dir=$META_DIR|" $FE_CONF

# Update ports in the configuration file
sed -i "s|^http_port=.*|http_port=$HTTP_PORT|" $FE_CONF
sed -i "s|^rpc_port=.*|rpc_port=$RPC_PORT|" $FE_CONF
sed -i "s|^query_port=.*|query_port=$QUERY_PORT|" $FE_CONF
sed -i "s|^edit_log_port=.*|edit_log_port=$EDIT_LOG_PORT|" $FE_CONF

# Print success message
echo "Configuration updated successfully."
echo "meta_dir set to $META_DIR"
echo "http_port set to $HTTP_PORT"
echo "rpc_port set to $RPC_PORT"
echo "query_port set to $QUERY_PORT"
echo "edit_log_port set to $EDIT_LOG_PORT"

# Step 3: Create a systemd service file
SERVICE_FILE="/etc/systemd/system/starrocks-fe.service"

cat << EOF > $SERVICE_FILE
[Unit]
Description=StarRocks Frontend Service
After=network.target

[Service]
Type=forking
User=root
ExecStart=$FE_DIR/fe/bin/start_fe.sh --host_type FQDN --daemon
ExecStop=$FE_DIR/fe/bin/stop_fe.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable starrocks-fe
systemctl start starrocks-fe

# Verify if the FE node is started successfully
sleep 5  # wait a few seconds for the FE node to start
cat $FE_DIR/fe/log/fe.log | grep thrift

echo "FE node started successfully as a systemd service."

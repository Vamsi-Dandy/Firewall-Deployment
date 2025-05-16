#!/bin/bash
echo "Setting up Ansible environment..."

python3 -m pip install --upgrade pip
pip install ansible boto3 botocore
ansible-galaxy collection install -r requirements.yml

echo "Environment setup complete."

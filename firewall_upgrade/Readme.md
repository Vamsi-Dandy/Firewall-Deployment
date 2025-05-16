# Palo Alto Firewall Upgrade Automation

This repository automates the upgrade process for Palo Alto VM-Series firewalls registered with Panorama and deployed behind AWS Gateway Load Balancers (GWLB). It supports Teams notifications and is region-aware, making it suitable for multi-region deployments.

---

## 🔧 Prerequisites

Before using this repository:

1. ✅ You must run from an **AWS EC2 instance** (Linux jump host) which has service-execution-iam **IAM role** 

2. ✅ The following **SSM parameters** must exist:
   - `/panwvmseries/devpanorama` — Panorama API key (SecureString).
   - `/firewall_upgrades/teams_webhook` — Teams incoming webhook URL (SecureString).

3. ✅ Install the required Python and Ansible dependencies (see [Setup Instructions](#setup-instructions)).

4. ✅ The firewalls must be:
   - Registered to Panorama
   - Configured in the `inventory/hosts.yml` with correct instance ID, region, and GWLB target group ARN

---

## 📁 Repository Structure
firewall_upgrades/<br>
├── ansible.cfg<br>
├── inventory/<br>
│ └── hosts.yml # Firewall inventory with region, instance ID, and TG ARN<br>
├── group_vars/<br>
│ └── all.yml # Global vars (e.g., Panorama IP and API key lookup)<br>
├── vars/<br>
│ └── upgrade_params.yml # PAN-OS version and options<br>
├── playbooks/<br>
│ └── upgrade_firewalls.yml # Main playbook<br>
├── roles/<br>
│ ├── upgrade_firewall/ # Role to upgrade firewalls and manage GWLB<br>
│ └── notify_teams/ # Role to send Teams alerts<br>
├── requirements.yml # Required Ansible collections<br>
└── setup_env.sh # Bootstrap script for environment setup<br>


---

## ⚙️ Setup Instructions

Run these steps from the AWS jump host where this repo is cloned.

### 1. Install Requirements

cd firewall_upgrades/<br>
bash setup_env.sh

This will:
    Install Python dependencies
    Install all required Ansible collections

### 2. Review and Edit Inventory

Update inventory/hosts.yml to list all the firewalls you want to upgrade:

firewalls:<br>
  hosts:<br>
    fw1:<br>
      ansible_host: <management-ip><br>
      instance_id: '<ec2-instance-id>'<br>
      target_group_arn: '<gwlb-target-group-arn>'<br>
      region: '<aws-region>'<br>

Each firewall must have:<br>
    * Its management IP (ansible_host)<br>
    * EC2 instance ID<br>
    * GWLB target group ARN<br>
    * AWS region<br>

### 3. Set Upgrade Parameters

Edit vars/upgrade_params.yml to set your desired PAN-OS version and source:

upgrade_version: "10.2.5"<br>
download_source: "panos"<br>
reboot_after_upgrade: true<br>

### 4. Run the Upgrade Playbook

Run the playbook with:

ansible-playbook -i inventory/hosts.yml playbooks/upgrade_firewalls.yml --extra-vars "target_phase=phase2"


## What This Playbook Does

For each firewall listed in the inventory:
* Deregisters the firewall from its GWLB target group
* Waits for existing flows to drain
* Downloads and installs the specified PAN-OS version via Panorama
* Reboots the firewall (if enabled)
* Waits for it to come back online
* Re-registers the firewall to its GWLB target group
* Sends a success/failure notification to Microsoft Teams


## 📣 Microsoft Teams Notification

On success or failure, a message is sent to the webhook URL stored in:
/firewall_upgrades/teams_webhook

The notification will include:
* The firewall name
* AWS region
* Upgrade status

# Terraform Modules for Network Security

This repository contains a collection of reusable Terraform modules designed to simplify and automate the deployment and management of various workflows . Each module is purpose-built for a specific use case such as firewall deployment, key pair creation, and software upgrades.

## Repository Structure

Each subdirectory in this repository represents an individual module. These modules are designed to be used independently or composed together depending on your infrastructure requirements.

### Current Modules

#### `aws_firewall_build`

This module provisions Palo Alto VM-Series firewalls in AWS. It supports bootstrap configuration via S3, integration with Panorama, and other customization options. Use this module to deploy new firewall instances.

#### `aws_keypair`

This module creates AWS EC2 key pairs that can be used to SSH into EC2 instances. It is typically used in conjunction with the `aws_firewall_build` module or other EC2-based workflows.

#### `firewall_upgrade`

This module automates the process of upgrading the PAN-OS software on existing VM-Series firewalls. It leverages Ansible or other tooling (depending on implementation) to perform non-disruptive upgrades across your fleet.

## Adding New Modules

To add a new module:
1. Create a new folder under the root of the repository.
2. Add your Terraform or automation code inside the folder.
3. Include a `README.md` in the new folder with details about the module's purpose, inputs, outputs, and usage examples.

## Usage

To use any module, navigate to the module directory and follow the instructions provided in its `README.md`. Example Terraform usage blocks and module-specific variables are documented there.

---

*This repository is intended for infrastructure engineers and automation specialists managing Palo Alto firewall deployments on AWS. Each module is tested and maintained independently.*


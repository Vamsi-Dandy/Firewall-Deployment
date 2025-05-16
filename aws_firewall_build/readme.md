# Palo Alto Firewall Deployment Module (AWS + Terraform + Python Bootstrap)

This Terraform module automates the deployment and bootstrapping of Palo Alto VM-Series firewalls in AWS. It supports launching multiple firewalls, dynamically generates bootstrap configurations per firewall, and logs metadata after Panorama registration.

---

## 🔧 Features

- Deploys multiple Palo Alto VM-Series firewalls in AWS.
- Dynamically creates unique bootstrap folders in S3 for each firewall instance.
- Uploads `init-cfg.txt` and license auth codes to S3 using a Python bootstrap script.
- Registers firewalls with Panorama using vm-auth key.
- Logs EC2 and Panorama metadata in S3 (instance ID, IP, serial number).
- Attaches firewalls to Gateway Load Balancer (GWLB) target group.

---

## 📦 S3 Folder Structure Created

The module creates a dedicated bootstrap directory per firewall inside the specified S3 bucket. Example structure:

`<bootstrap-bucket>`/<br>
└── pa-`<env>`-`<region>`-1<br>
├── config/<br>
│ └── init-cfg.txt<br>
├── content/<br>
├── license/<br>
│ └── authcodes<br>
├── software/<br>
├── plugins/<br>
└── firewall_list/<br>
└── `<serial>`.json<br>

---

## 🧰 Prerequisites

- An AWS account with required IAM permissions.
- An S3 bucket for storing bootstrap files.We will be using the fdss3-<account_no.>-misc-data-<region> bucket that has been created by Public Cloud Team in all the accounts.
- A Panorama instance with API access.
- Template Stack and Device Group created in Panorama.
- Terraform 1.0+ installed.
- Python 3 with `boto3` and `requests` installed.
- IAM Instance Profile with permissions to read SSM parameters and access S3.

---

## 🚀 Usage

All the Terraform variable definitions and usage examples for calling this module are maintained in the following repository:

👉 [SecurityAutomation/NetSec-vars](https://github.factset.com/SecurityAutomation/NetSec-vars)

Please refer to the `firewall-*.tfvars` and environment-specific folders in that repo for usage patterns.

---

## 📁 Files Explained

- `bootstrap_generator.py`: 
  - Creates a structured S3 bootstrap directory per firewall.
  - Generates `init-cfg.txt` dynamically using EC2 metadata and Panorama details.
  - Uploads license file (`authcodes`) using Panorama API.

- `log_firewall_metadata.py`: 
  - Waits for firewall to register with Panorama.
  - Logs EC2 instance metadata and firewall serial number to S3 as JSON.

- `main.tf`: 
  - Defines AWS resources (EC2 instances, IAM roles, etc.).
  - Invokes the Python scripts using `null_resource` and `local-exec`.

---

## 📤 Outputs

This module outputs common metadata such as:

- Public IP addresses of firewalls
- EC2 instance IDs
- Bootstrap folder prefixes

These outputs can be used for monitoring or downstream automation.

---

## 🔐 Security Notes

- API keys, vm-auth-keys, and other secrets are pulled securely from AWS SSM Parameter Store (as SecureString).
- Ensure least privilege IAM policies are used for accessing S3, SSM, and EC2.

---

## 🛠 Troubleshooting

- Check `/var/log/cloud-init.log` and `/var/log/user-data.log` on the firewall instance if bootstrapping fails.
- Verify S3 objects were correctly uploaded and match the expected bootstrap folder structure.
- Confirm Panorama connectivity and API access if registration or license upload fails.

---

## 📚 References

- [Palo Alto Networks VM-Series Documentation](https://docs.paloaltonetworks.com)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Boto3 AWS SDK for Python](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)

---

## 📬 Support

For internal support, please contact the **NetSec Automation Team** or open an issue in [SecurityAutomation/NetSec-vars](https://github.factset.com/SecurityAutomation/NetSec-vars).

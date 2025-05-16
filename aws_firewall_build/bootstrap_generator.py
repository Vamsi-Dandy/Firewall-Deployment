#!/usr/bin/env python3

import boto3
import argparse
import logging
import requests
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger()

def create_folders_in_s3(bucket_name, region, prefix):
    s3 = boto3.client('s3', region_name=region)
    folders = [
        f"{prefix}/config/",
        f"{prefix}/content/",
        f"{prefix}/license/",
        f"{prefix}/software/",
        f"{prefix}/plugins/"
    ]
    for folder in folders:
        try:
            s3.put_object(Bucket=bucket_name, Key=folder)
            logger.info(f"✔️ Created folder: s3://{bucket_name}/{folder}")
        except ClientError as e:
            logger.error(f"❌ Failed to create folder {folder}: {e}")
            raise

def upload_to_s3(bucket, key, content, region):
    s3 = boto3.client('s3', region_name=region)
    try:
        s3.put_object(Bucket=bucket, Key=key, Body=content)
        logger.info(f"✔️ Uploaded: s3://{bucket}/{key}")
    except ClientError as e:
        logger.error(f"❌ Failed to upload {key}: {e}")
        raise

def get_ssm_param(parameter_name, region):
    ssm = boto3.client('ssm', region_name=region)
    try:
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
        return response['Parameter']['Value']
    except ClientError as e:
        logger.error(f"❌ Failed to fetch SSM parameter {parameter_name}: {e}")
        raise

def get_vm_authcode_from_panorama(panorama_ip, api_key):
    url = f"https://{panorama_ip}/api/?type=op&cmd=<request><bootstrap><vm-auth-key><generate><lifetime>1</lifetime></generate></vm-auth-key></bootstrap></request>&key={api_key}"
    try:
        response = requests.get(url, verify=False, timeout=10)
        response.raise_for_status()
        logger.info(f"Panorama response: {response.text}")
        start = response.text.find("VM auth key ") + len("VM auth key ")
        end = response.text.find(" generated", start)
        if start > -1 and end > -1:
            return response.text[start:end].strip()
        raise RuntimeError("VM auth key not found in response")
    except Exception as e:
        logger.error(f"❌ Error fetching vm-auth-key from Panorama: {e}")
        raise

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--region", required=True, help="AWS region for the S3 bucket")
    parser.add_argument("--ssm-region", required=True, help="AWS region where SSM parameters are stored")
    parser.add_argument("--account-id", required=True)
    parser.add_argument("--panorama-ip", required=True)
    parser.add_argument("--panorama-api-key", required=True)
    parser.add_argument("--template-stack", required=True)
    parser.add_argument("--device-group", required=True)
    parser.add_argument("--hostname", required=True)
    parser.add_argument("--bootstrap-prefix", required=True, help="S3 prefix (folder path) for storing bootstrap files")
    parser.add_argument("--ssm-authcode-param", required=True)
    parser.add_argument("--ssm-pin-id-param", required=True)
    parser.add_argument("--ssm-pin-value-param", required=True)
    args = parser.parse_args()

    bucket_name = f"fdss3-{args.account_id}-misc-data-{args.region}"
    logger.info("🚀 Starting bootstrap generation")
    logger.info(f"📦 Target bucket: {bucket_name}")
    logger.info(f"📂 Bootstrap prefix: {args.bootstrap_prefix}")
    logger.info(f"🔧 Hostname: {args.hostname}")

    # Fetch parameters
    vm_auth_key_panorama = get_vm_authcode_from_panorama(args.panorama_ip, args.panorama_api_key)
    vm_auth_key_ssm = get_ssm_param(args.ssm_authcode_param, args.ssm_region)
    registration_pin_id = get_ssm_param(args.ssm_pin_id_param, args.ssm_region)
    registration_pin_value = get_ssm_param(args.ssm_pin_value_param, args.ssm_region)

    # Build init-cfg.txt
    init_cfg = f"""type=dhcp-client
hostname={args.hostname}
vm-auth-key={vm_auth_key_panorama}
panorama-server={args.panorama_ip}
tplname={args.template_stack}
dgname={args.device_group}
dns-primary=169.254.169.253
dns-secondary=8.8.8.8
dhcp-send-hostname=yes
dhcp-send-client-id=yes
dhcp-accept-server-hostname=no
dhcp-accept-server-domain=yes
vm-series-auto-registration-pin-id={registration_pin_id}
vm-series-auto-registration-pin-value={registration_pin_value}
"""

    logger.info(f"📝 init-cfg.txt content:\n{init_cfg}")

    # Create folder structure and upload files to S3
    create_folders_in_s3(bucket_name, args.region, args.bootstrap_prefix)
    upload_to_s3(bucket_name, f"{args.bootstrap_prefix}/config/init-cfg.txt", init_cfg, args.region)
    upload_to_s3(bucket_name, f"{args.bootstrap_prefix}/license/authcodes", vm_auth_key_ssm, args.region)

    logger.info("✅ Bootstrap files uploaded successfully")

if __name__ == "__main__":
    main()
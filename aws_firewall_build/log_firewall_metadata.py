#!/usr/bin/env python3

import argparse
import logging
import boto3
import requests
import json
import time
from datetime import datetime
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger()

def get_instance_metadata(instance_name, region):
    ec2 = boto3.client('ec2', region_name=region)
    filters = [
        {'Name': 'tag:Name', 'Values': [instance_name]},
        {'Name': 'instance-state-name', 'Values': ['running']}
    ]
    try:
        reservations = ec2.describe_instances(Filters=filters)['Reservations']
        if not reservations:
            raise RuntimeError(f"No instance found with name: {instance_name}")
        instance = reservations[0]['Instances'][0]
        return {
            'instance_id': instance['InstanceId'],
            'private_ip': instance.get('PrivateIpAddress')
        }
    except ClientError as e:
        logger.error(f"❌ Failed to fetch EC2 instance metadata: {e}")
        raise

def get_serial_number_from_panorama(panorama_ip, api_key, hostname, retries=50, delay=30):
    url = f"https://{panorama_ip}/api/?type=op&cmd=<show><devices><all></all></devices></show>&key={api_key}"
    for attempt in range(1, retries + 1):
        try:
            logger.info(f"🌐 Querying Panorama for serial number (attempt {attempt}/{retries})")
            response = requests.get(url, verify=False, timeout=10)
            response.raise_for_status()

            if hostname in response.text:
                start = response.text.find("<serial>") + len("<serial>")
                end = response.text.find("</serial>", start)
                serial = response.text[start:end].strip()
                logger.info(f"✅ Found serial number: {serial}")
                return serial

            logger.warning(f"⚠️ Hostname {hostname} not found in Panorama response, retrying in {delay}s...")
            time.sleep(delay)

        except Exception as e:
            logger.error(f"❌ Error querying Panorama: {e}")
            time.sleep(delay)

    raise RuntimeError(f"Hostname {hostname} not found in Panorama output after {retries} attempts")

def upload_to_s3(bucket, key, content, region):
    s3 = boto3.client('s3', region_name=region)
    try:
        s3.put_object(Bucket=bucket, Key=key, Body=content)
        logger.info(f"✔️ Uploaded to s3://{bucket}/{key}")
    except ClientError as e:
        logger.error(f"❌ Failed to upload metadata to S3: {e}")
        raise

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--region", required=True)
    parser.add_argument("--hostname", required=True)
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--panorama-ip", required=True)
    parser.add_argument("--panorama-api-key", required=True)
    parser.add_argument("--bootstrap-prefix", required=True)
    args = parser.parse_args()

    logger.info(f"🔍 Getting EC2 metadata for {args.hostname}")
    meta = get_instance_metadata(args.hostname, args.region)

    logger.info(f"🔍 Getting serial number from Panorama")
    serial = get_serial_number_from_panorama(args.panorama_ip, args.panorama_api_key, args.hostname)

    # Build JSON payload
    firewall_info = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "hostname": args.hostname,
        "instance_id": meta["instance_id"],
        "private_ip": meta["private_ip"],
        "serial_number": serial
    }

    s3_key = f"{args.bootstrap_prefix}/firewall_list/{serial}.json"
    upload_to_s3(args.bucket, s3_key, json.dumps(firewall_info, indent=2), args.region)

if __name__ == "__main__":
    main()

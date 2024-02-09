#!/usr/bin/env python3
#
# S3obd.py
# -----------
# A simple Python script that can download files from an open AWS S3 bucket.
#
# Coded by: Riccardo Mollo (riccardomollo84@gmail.com)
#

import argparse
import os
import requests
import xml.etree.ElementTree as ET


def check_directory(directory_path):
    if not os.path.exists(directory_path):
        try:
            os.makedirs(directory_path)
            print(f"Directory '{directory_path}' created successfully.")
        except OSError as e:
            print(f"Error: Unable to create directory '{directory_path}': {e}")
            return False

    if os.access(directory_path, os.W_OK) and os.access(directory_path, os.R_OK):
        print(f"Directory '{directory_path}' is writable and readable.")
        return True
    else:
        print(f"Error: Directory '{directory_path}' is not writable or readable.")
        return False


def download_file(url, folder_path, file_name):
    file_path = os.path.join(folder_path, file_name)

    response = requests.get(url)

    if response.status_code == 200:
        with open(file_path, "wb") as file:
            file.write(response.content)
        print(f"File downloaded and saved at: {file_path}")
    else:
        print(
            f"Error: Unable to download file from {url}. Status code: {response.status_code}"
        )


parser = argparse.ArgumentParser(prog="S3obd.py")
parser.add_argument("-u", "--url", help="URL of the open AWS S3 bucket", required=True)
parser.add_argument(
    "-d", "--directory", help="output directory to save files into", required=True
)
args = parser.parse_args()
url = args.url
directory = args.directory

if not check_directory(directory):
    exit(0)

if not url.endswith("/"):
    url += "/"

response = requests.get(url)

if response.status_code == 200:
    xml_content = response.text

    root = ET.fromstring(xml_content)
    namespace = {"ns": "http://s3.amazonaws.com/doc/2006-03-01/"}

    keys = [
        content.find("ns:Key", namespace).text
        for content in root.findall(".//ns:Contents", namespace)
    ]

    for key in keys:
        download_file(url + key, directory, key)
else:
    print(
        f"Error: Unable to fetch content from {url}. Status code: {response.status_code}"
    )

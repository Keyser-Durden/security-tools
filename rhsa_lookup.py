#!/usr/bin/python3
import sys
import os
import requests
import configparser
import json

# Define the path to the configuration file
config_file_path = '../etc/rhsa_lookup.conf'

# Get the absolute path to the script's directory
script_directory = os.path.dirname(os.path.abspath(__file__))

# Combine the script's directory with the configuration file path
config_file_path = os.path.join(script_directory, config_file_path)

# Check if an RHSA ID argument is provided
if len(sys.argv) != 2:
    print("Usage: python rhsa_lookup.py <RHSA-ID>")
    sys.exit(1)

# Retrieve the RHSA ID from the command line argument and convert it to uppercase
rhsa_id = sys.argv[1].upper()

# Function to obtain the access token from the configuration file
def get_access_token_from_config():
    try:
        # Check if the configuration file exists
        if not os.path.isfile(config_file_path):
            print(f"Error: Configuration file not found at {config_file_path}")
            return None

        # Read configuration data from the file
        config = configparser.ConfigParser()
        config.read(config_file_path)

        # Check if 'Credentials' and 'offline_token' are present in the configuration file
        if 'Credentials' in config and 'offline_token' in config['Credentials']:
            return config['Credentials']['offline_token']
        else:
            print("Error: 'offline_token' not found in the configuration file")
            return None
    except Exception as e:
        print(f"An error occurred while reading the configuration file: {str(e)}")
        return None

# Get the access token from the configuration file
access_token = get_access_token_from_config()

# Check if we successfully obtained the access token
if access_token:
    # Construct the API URL to fetch advisory information
    api_url = f"https://api.access.redhat.com/management/v1/errata/{rhsa_id}"

    # Set up headers with authentication and "accept" header
    headers = {
        "Authorization": f"Bearer {access_token}",
        "accept": "application/json"
    }

    try:
        # Make a GET request to the Red Hat Customer Portal API
        response = requests.get(api_url, headers=headers)

        # Check if the request was successful
        if response.status_code == 200:
            try:
                # Attempt to parse the response as JSON
                rhsa_data = response.json()

                # Extract and print RHSA information
                print(f"RHSA ID: {rhsa_data.get('id')}")
                print(f"Title: {rhsa_data.get('synopsis')}")
                print(f"Description: {rhsa_data.get('description')}")
                print(f"Issued: {rhsa_data.get('issued')}")
                print(f"Severity: {rhsa_data.get('severity')}")

                # Extract and print affected products
                print("\nAffected Products:")
                for product in rhsa_data.get('affectedProducts', []):
                    print(f"Product: {product}")

                # Extract and print CVEs
                print("\nCVEs:")
                for cve in rhsa_data.get('cves', []):
                    print(f"CVE: {cve}")
            except ValueError as ve:
                print(f"Failed to parse JSON response: {ve}")
        elif response.status_code == 400:
            # Handle 400 Bad Request errors
            error_description = response.json().get('error', {}).get('message')
            print(f"Error 400: {error_description}")
        elif response.status_code in [401, 402, 403, 404, 500]:
            # Handle 401, 402, 403, 404, and 500 errors
            error_description = response.json().get('error', {}).get('message')
            print(f"Error {response.status_code}: {error_description}")
        else:
            print(f"Failed to retrieve RHSA information. Status code: {response.status_code}")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

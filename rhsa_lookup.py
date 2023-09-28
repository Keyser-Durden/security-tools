#!/usr/bin/python3
import sys
import os
import requests
import configparser

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

# Check if the configuration file exists
if not os.path.isfile(config_file_path):
    print(f"Error: Configuration file not found at {config_file_path}")
    sys.exit(1)

# Read API token from the configuration file
config = configparser.ConfigParser()
config.read(config_file_path)

if 'Credentials' in config and 'api_token' in config['Credentials']:
    api_token = config['Credentials']['api_token']
else:
    print("Error: API token not found in the configuration file")
    sys.exit(1)

# Construct the API URL to fetch advisory information
api_url = f"https://api.access.redhat.com/management/v1/advisory/{rhsa_id}"

# Set up headers with authentication
headers = {
    "Authorization": f"Bearer {api_token}"
}

try:
    # Make a GET request to the Red Hat Customer Portal API
    response = requests.get(api_url, headers=headers)

    # Check if the request was successful
    if response.status_code == 200:
        rhsa_data = response.json()
        
        # Extract and print RHSA information
        print(f"RHSA ID: {rhsa_data['advisory_name']}")
        print(f"Title: {rhsa_data['synopsis']}")
        print(f"Description: {rhsa_data['description']}")
        
        # Extract and print product information
        print("\nProduct Information:")
        for product in rhsa_data['affected_products']:
            print(f"Product Name: {product['product_name']}")
            print(f"Product Version: {product['product_version']}")
        
        # Extract and print affected packages (errata)
        print("\nAffected Packages (Errata):")
        for erratum in rhsa_data['errata']:
            print(f"Erratum ID: {erratum['advisory_name']}")
            print(f"Severity: {erratum['severity']}")
            print(f"Package Updates: {', '.join(erratum['package_names'])}")
    elif response.status_code == 400:
        # Handle 400 Bad Request errors
        error_description = response.json().get('detail')
        print(f"Error 400: {error_description}")
    else:
        print(f"Failed to retrieve RHSA information. Status code: {response.status_code}")
except Exception as e:
    print(f"An error occurred: {str(e)}")


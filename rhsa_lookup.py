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

# Function to obtain the access token
def get_access_token():
    try:
        # Read offline_token from a file
        with open('offline_token.txt', 'r') as token_file:
            offline_token = token_file.read().strip()

        # Define the authentication request data
        auth_data = {
            "grant_type": "refresh_token",
            "client_id": "rhsm-api",
            "refresh_token": offline_token
        }

        # Make a POST request to obtain the access token
        response = requests.post(
            "https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token",
            data=auth_data
        )

        # Check if the request was successful
        if response.status_code == 200:
            response_data = json.loads(response.text)
            return response_data.get('access_token')
        else:
            print(f"Error obtaining access token. Status code: {response.status_code}")
            return None
    except Exception as e:
        print(f"An error occurred while obtaining the access token: {str(e)}")
        return None

# Get the access token
access_token = get_access_token()

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


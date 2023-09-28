#!/usr/bin/python3
import sys
import requests

# Remember to...   pip install requests

# Check if a CVE ID argument is provided
if len(sys.argv) != 2:
    print("Usage: python cve_lookup.py <CVE-ID>")
    sys.exit(1)

# Retrieve the CVE ID from the command line argument and convert it to uppercase
cve_id = sys.argv[1].upper()

# Construct the NVD API URL
nvd_api_url = f"https://services.nvd.nist.gov/rest/json/cve/1.0/{cve_id}"

try:
    # Send a GET request to the NVD API
    response = requests.get(nvd_api_url)

    # Check if the request was successful
    if response.status_code == 200:
        cve_data = response.json()
        
        # Extract relevant information from the response
        cve_description = cve_data['result']['CVE_Items'][0]['cve']['description']['description_data'][0]['value']
        cve_published_date = cve_data['result']['CVE_Items'][0]['publishedDate']
        
        # Print the CVE information
        print(f"CVE ID: {cve_id}")
        print(f"Description: {cve_description}")
        print(f"Published Date: {cve_published_date}")
    else:
        print(f"Failed to retrieve CVE information. Status code: {response.status_code}")
except Exception as e:
    print(f"An error occurred: {str(e)}")


#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <CVE-ID>"
    exit 1
fi

# Retrieve the CVE ID from the command line argument and convert it to uppercase
cve_id=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# Construct the NVD API URL
nvd_api_url="https://services.nvd.nist.gov/rest/json/cve/1.0/$cve_id"

# Send a GET request to the NVD API and capture the response
response=$(curl -s -w "%{http_code}" -o /dev/null "$nvd_api_url")

# Check if the request was successful
if [ "$response" -eq 200 ]; then
    # Fetch the CVE information after confirming the response is successful
    cve_data=$(curl -s "$nvd_api_url" | jq -r '.result.CVE_Items[0]')
    cve_description=$(echo "$cve_data" | jq -r '.cve.description.description_data[0].value')
    cve_published_date=$(echo "$cve_data" | jq -r '.publishedDate')

    # Print the CVE information
    echo "CVE ID: $cve_id"
    echo "Description: $cve_description"
    echo "Published Date: $cve_published_date"
else
    echo "Failed to retrieve CVE information. Status code: $response"
fi

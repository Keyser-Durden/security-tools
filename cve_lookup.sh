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
response=$(curl -s "$nvd_api_url")

# Check if the request was successful
if [ "$(echo "$response" | jq -r '.statusCode')" == "200" ]; then
    cve_description=$(echo "$response" | jq -r '.result.CVE_Items[0].cve.description.description_data[0].value')
    cve_published_date=$(echo "$response" | jq -r '.result.CVE_Items[0].publishedDate')

    # Print the CVE information
    echo "CVE ID: $cve_id"
    echo "Description: $cve_description"
    echo "Published Date: $cve_published_date"
else
    echo "Failed to retrieve CVE information. Status code: $(echo "$response" | jq -r '.statusCode')"
fi

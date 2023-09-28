#!/bin/bash

# Put your offline_token as a single line of text into ./etc/rh_api_token.txt

# Read the offline token from the first line of ./etc/rh_api_token.txt
offline_token=$(head -n 1 ./etc/rh_api_token.txt)

# Convert the RHSA variable to uppercase (macOS compatible)
RHSA=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# Define the function to obtain the access token
function getAccessToken() {
  curl_result=$(curl -s "https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token" \
    -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token="$offline_token")
  access_token=$(echo "$curl_result" | jq -r '.access_token')
  echo "$access_token"
}

# Call the function to get the access token and store it in a variable
token=$(getAccessToken)

# Function to get RHSA information using the access token
get_rhsa_info() {
  # Use this URL to get data: https://api.access.redhat.com/management/v1/errata/$RHSA
  # You can use the $token variable to include the access token in the request headers
  json_response=$(curl -s -H "Authorization: Bearer $token" "https://api.access.redhat.com/management/v1/errata/$RHSA")

  # Extract the "cves" field and remove leading/trailing spaces
  cves=$(echo "$json_response" | jq -r '.body.cves' | tr -d '[:space:]')

  # Split the CVEs based on the "CVE-" prefix and print them one per line
  echo "$cves" | grep -o 'CVE-[0-9]\{4,9\}-[0-9]\{4,9\}'
}

# Call the get_rhsa_info function to retrieve RHSA information and print related CVEs
get_rhsa_info

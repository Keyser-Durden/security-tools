#!/bin/bash

# Initialize verbose flag to false
verbose=false

# Check for the -v flag
while getopts ":v" opt; do
  case $opt in
    v)
      verbose=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Shift the command-line arguments to exclude the processed options
shift $((OPTIND-1))

# Check if the script is called without an argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 [-v] <RHSA>"
  exit 1
fi

# Function to validate the RHSA format
validate_rhsa_format() {
    local rhsa_pattern="RHSA-[0-9]{4}:[0-9]+"
    if [[ ! $1 =~ $rhsa_pattern ]]; then
        echo "Invalid RHSA format. Please provide an RHSA in the format RHSA-<4 digits>:<digits>."
        exit 1
    fi
}

# Validate the RHSA format
validate_rhsa_format "$1"

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

  # Check if the "cves" field exists in the JSON response
  if [[ $(echo "$json_response" | jq '.body.cves') != "null" ]]; then
    # Extract the "cves" field and remove leading/trailing spaces
    cves=$(echo "$json_response" | jq -r '.body.cves' | tr -d '[:space:]')

    # Split the CVEs based on the "CVE-" prefix and print them one per line
    cve_list=$(echo "$cves" | grep -o 'CVE-[0-9]\{4,9\}-[0-9]\{4,9\}' | tr '\n' ',' | sed 's/,$//')

    # Output each CVE,RHSA pair on a separate line
    for cve in $(echo "$cve_list" | tr ',' ' '); do
      echo "$RHSA,$cve"
    done
  else
    # Output "CVE,RHSA" if there are no related CVEs
    echo "$RHSA,"
  fi
}

# Call the get_rhsa_info function to retrieve RHSA information and print related CVEs
get_rhsa_info

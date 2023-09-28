#!/bin/bash

while getopts "cdpr" opt; do
    case $opt in
        c)
            cve_flag=true
            ;;
        d)
            description_flag=true
            ;;
        p)
            published_date_flag=true
            ;;
        r)
            rhsa_flag=true
            ;;
        \?)
            echo "Usage: $0 [-c] [-d] [-p] [-r] <CVE-ID>"
            exit 1
            ;;
    esac
done

# Shift to the next argument after processing flags
shift $((OPTIND-1))

# Check if an argument (CVE-ID) is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 [-c] [-d] [-p] [-r] <CVE-ID>"
    exit 1
fi

# Retrieve the CVE ID from the command line argument and convert it to uppercase
cve_id=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# Construct the NVD API URL
nvd_api_url="https://services.nvd.nist.gov/rest/json/cve/1.0/$cve_id"

# Send a GET request to the NVD API and capture the response, then parse it with jq
cve_info=$(curl -s "$nvd_api_url" | jq -r '.result.CVE_Items[0] | { "CVE ID": .cve.CVE_data_meta.ID, "Description": .cve.description.description_data[0].value, "Published Date": .publishedDate, "Related RHSA": .cve.references.reference_data[] | select(.refsource == "REDHAT") | .name }')

# Check which flags were provided and display the corresponding information
if [ -n "$cve_info" ]; then
    if [ "$cve_flag" == true ]; then
        echo "CVE ID: $(echo "$cve_info" | jq -r '.["CVE ID"]')"
    fi
    if [ "$description_flag" == true ]; then
        echo "Description: $(echo "$cve_info" | jq -r '.Description')"
    fi
    if [ "$published_date_flag" == true ]; then
        echo "Published Date: $(echo "$cve_info" | jq -r '.["Published Date"]')"
    fi
    if [ "$rhsa_flag" == true ]; then
        echo "Related RHSA: $(echo "$cve_info" | jq -r '.["Related RHSA"]')"
    fi
else
    echo "Failed to retrieve CVE information for CVE ID: $cve_id"
fi


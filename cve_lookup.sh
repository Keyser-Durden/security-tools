#!/bin/bash

# Initialize variables for flags
cve_flag=false
description_flag=false
published_date_flag=false
rhsa_flag=false
verbose_flag=false

function show_usage {
    echo "Usage: $0 [-c] [-d] [-p] [-r] [-v] <CVE-ID>"
    echo "Options:"
    echo "  -c    Show CVE ID"
    echo "  -d    Show Description"
    echo "  -p    Show Published Date"
    echo "  -r    Show Related RHSA"
    echo "  -v    Show output descriptions (e.g., 'Related RHSA:')"
    exit 1
}

while getopts "cdprv" opt; do
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
        v)
            verbose_flag=true
            ;;
        \?)
            show_usage
            ;;
    esac
done

# Shift to the next argument after processing flags
shift $((OPTIND-1))

# Check if the CVE ID is provided
if [ $# -ne 1 ]; then
    show_usage
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
        if [ "$verbose_flag" == true ]; then
            echo "CVE ID: $(echo "$cve_info" | jq -r '.["CVE ID"]')"
        else
            echo "$(echo "$cve_info" | jq -r '.["CVE ID"]')"
        fi
    fi
    if [ "$description_flag" == true ]; then
        if [ "$verbose_flag" == true ]; then
            echo "Description: $(echo "$cve_info" | jq -r '.Description')"
        else
            echo "$(echo "$cve_info" | jq -r '.Description')"
        fi
    fi
    if [ "$published_date_flag" == true ]; then
        if [ "$verbose_flag" == true ]; then
            echo "Published Date: $(echo "$cve_info" | jq -r '.["Published Date"]')"
        else
            echo "$(echo "$cve_info" | jq -r '.["Published Date"]')"
        fi
    fi
    if [ "$rhsa_flag" == true ]; then
        if [ "$verbose_flag" == true ]; then
            echo "Related RHSA: $(echo "$cve_info" | jq -r '.["Related RHSA"]')"
        else
            echo "$(echo "$cve_info" | jq -r '.["Related RHSA"]')"
        fi
    fi
else
    echo "Failed to retrieve CVE information for CVE ID: $cve_id"
fi

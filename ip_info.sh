#!/usr/bin/env bash

set -e

# Main script logic
main() {
	local ip
	if [[ -z $1 ]]; then
		read -p "Enter the target IP address: " ip
	else
		ip=$1
	fi

	validate_ip "$ip"

    # Fetch IP information
    local ip_info=$(fetch_ip_info "$ip")
    local iplocation_info=$(fetch_iplocation_info "$ip")

    # Combine responses
    local combined_info=$(jq -s '.[0] * .[1]' <<< "$ip_info"$'\n'"$iplocation_info" )

    # Check for API errors
    local response_code=$(jq -r '.response_code' <<< "$combined_info")
    local status=$(jq -r '.status' <<< "$combined_info")

    if [[ $response_code != 200 ]] || [[ $status != "success" ]]; then
	    echo "Operation failed due to unsuccessful responses from the IP APIs."
	    exit 1
    fi

    # Generate Google Maps link
    local lat=$(jq -r '.lat' <<< "$ip_info")
    local lon=$(jq -r '.lon' <<< "$ip_info")
    local map_link=$(generate_map_link "$lat" "$lon")

    # Add map link to the combined info
    combined_info=$(jq --arg map_link "$map_link" '. + {"See location on Google Maps": $map_link}' <<< "$combined_info")

    # Output the final result
    echo "$combined_info" | jq

    # Fetch and display DNS information
    fetch_dns_info
}


### Functions ###

# Function to validate IP address format
validate_ip() {
	local ip=$1

	# Regex for IPv4
	local ipv4_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
	# Regex for IPv6 (simplified to match valid IPv6 formats)
	local ipv6_regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'

	if [[ ! $ip =~ $ipv4_regex ]] && [[ ! $ip =~ $ipv6_regex ]]; then
		echo "Error: Invalid IP address format. Must be a valid IPv4 or IPv6 address."
		exit 1
	fi
}

# Function to fetch IP information
fetch_ip_info() {
	local ip=$1
	local fields='status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,mobile,proxy,hosting,query'
	local url="http://ip-api.com/json/$ip?fields=$fields"
	curl -s "$url"
}

# Function to fetch additional IP location info
fetch_iplocation_info() {
	local ip=$1
	local url="https://api.iplocation.net/?ip=$ip"
	curl -s "$url"
}

# Function to generate Google Maps link
generate_map_link() {
	local lat=$1
	local lon=$2
	echo "https://www.google.com/maps/search/?api=1&query=$lat,$lon"
}

# Function to fetch DNS information
fetch_dns_info() {
	local dns_url=$(curl -s -X GET http://edns.ip-api.com/json | grep -oP 'href="\K[^"]+')
	curl -s "$dns_url" | jq
}

# Run the script (Main Driver)
main "$1"

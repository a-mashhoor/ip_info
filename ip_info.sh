#!/usr/bin/env bash

set -e

if [[ ! $1 ]]; then

	read -p "enter the target IP addr: " IP
	echo $IP
	ip=$IP
else
	ip=$1
fi

address=http://ip-api.com/json/$ip

flds='status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,mobile,proxy,hosting,query'

curl -s $address\?fields=$(printf $flds) > tmp1
curl -s https://api.iplocation.net/\?ip=$ip > tmp2


response_status=$(jq -s '.[0] * .[1] | {"The IP info Result": .}' tmp1 tmp2 > tmp3;\
	jq -r '.[].response_code' tmp3)

status_s=$(jq -r '.[].status' tmp3)

if [[ $response_status != 200 ]] && [[ status_s != "success" ]]; then
	echo opreation faild due to unsuccessful responses from the IP APIs
	rm -f tmp1 tmp2 tmp3
	exit 1
fi

# I know I can just Use jq -r but I like sed!
geo_coordinates=$(jq ". | [.lat, .lon]  | @csv " tmp1 | sed 's/"//g')
map_link="https://www.google.com/maps/search/?api=1&query=$geo_coordinates"

jq --arg gc "$map_link" ' .[] += {"See location on Google Maps": $gc }' tmp3

dnss=$(curl -s -X GET http://edns.ip-api.com/json \
	| sed 's/href=/\nhref=/g' \
	| grep href=\" \
	| sed 's/.*href="//g;s/".*//g')

curl -s $dnss | jq

rm -f tmp1 tmp2 tmp3

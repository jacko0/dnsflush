#!/bin/bash
echo "=== dnsflush Test Script ==="

echo "1. Clearing DNS cache before test..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
sleep 2

echo "2. Checking DNS cache statistics before..."
echo "Before:"
sudo dscacheutil -statistics | grep -E "Cache|Responses"

echo -e "\n3. Running your dnsflush tool..."
/Users/stevenjackson/Downloads/dnsflush

echo -e "\n4. Checking DNS cache statistics after..."
echo "After:"
sudo dscacheutil -statistics | grep -E "Cache|Responses"

echo -e "\n✅ Test complete!"
echo "If the 'Responses' number increased or 'Cache' changed, your tool is working."

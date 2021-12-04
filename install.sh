#!/bin/bash
#tools for subdomain.sh

apt-get update
apt-get install ffuf

go get -u github.com/tomnomnom/anew
go get -u github.com/tomnomnom/assetfinder
go get -v github.com/OWASP/Amass/v3/...
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
GO111MODULE=on go get -v github.com/projectdiscovery/shuffledns/cmd/shuffledns
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go get github.com/tomnomnom/waybackurls
go install github.com/lc/gau/v2/cmd/gau@latest
go get -u github.com/tomnomnom/unfurl
go install -v github.com/projectdiscovery/notify/cmd/notify@latest

echo "Install manually shuffledns and urldedupe"
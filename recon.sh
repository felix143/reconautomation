#!/bin/bash

domain=$1
resolvers="/root/Downloads/resolvers.txt"
dnswordlist="/root/Downloads/SecLists/Discovery/DNS/all.txt"
mkdir -p $domain $domain/recon

echo "Using assetfinder results"
assetfinder -subs-only $1 | anew -q $domain/subdomains_assetfinder.txt
#sed 's/A.*//' resolved.txt | sed 's/CN.*//' | sed 's/\..$//' | sort -u | anew $domain/subdomains_assetfinder.txt
#rm resolved.txt

echo "Using amass"
amass enum -passive -d $domain -max-dns-queries 200 -o $domain/subdomains_amass.txt

echo "Using subfinder results"
subfinder -d $1 -r $resolvers | anew -q $domain/subdomains_subfinder.txt

echo "Using RapidDNS.io"
curl -s "https://rapiddns.io/subdomain/$1?full=1#result" | grep "<td><a" | cut -d '"' -f 2 | grep $1 | cut -d '/' -f3 | sed 's/#results//g' | sort -u | anew -q $domain/subdomains_rapiddns.txt

echo "bufferover"
curl -s https://dns.bufferover.run/dns?q=.$1 |jq -r .FDNS_A[]|cut -d',' -f2|sort -u | anew -q $domain/subdomains_bufferover.txt

echo "riddler"
curl -s "https://riddler.io/search/exportcsv?q=pld:$1" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | anew -q $domain/subdomains_riddler.txt

echo "certspotter"
curl -s "https://api.certspotter.com/v1/issuances?domain=$1&expand=dns_names&expand=issuer&expand=cert" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | anew -q $domain/subdomains_cerspotter.txt

echo "JLDC"
curl -s "https://jldc.me/anubis/subdomains/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | anew -q $domain/subdomains_jdlc.txt

echo "cert.sh"
curl -s "https://crt.sh/?q=%25.$1&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | anew -q $domain/subdomains_crt.txt

shuffledns -d $domain -w $dnswordlist -r $resolvers -o $domain/subdomains_shuffledns.txt

cat $domain/subdomains_*.txt | sort -u | anew -q $domain/recon/subdomain_results.txt
cat $domain/recon/subdomain_results.txt | massdns -r $resolvers -t A -o S -w $domain/resolved.txt
sed 's/A.*//' $domain/resolved.txt | sed 's/CN.*//' | sed 's/\..$//' | sort -u | anew $domain/recon/resolved_domains.txt

rm $domain/resolved.txt
rm -rf $domain/subdomains_*.txt

echo "--------------------------------------------------------------------"

echo "testing for live domains"
cat $domain/recon/resolved_domains.txt | httpx -status-code -t 200| grep "200" | awk {'print $1'} | anew $domain/recon/live_200_subdomains.txt
cat $domain/recon/resolved_domains.txt | httpx -t 200| anew $domain/recon/live_subdomains.txt

echo "--------------------------------------------------------------------"
 
cat $domain/recon/live_subdomains.txt | nuclei -t /root/nuclei-templates/ -c 100 -severity critical,high,medium,low -o $domain/recon/nuclei_results.txt	| notify -silent
cat $domain/recon/live_subdomains.txt | nuclei -t /root/nuceli-templates/ -c 100 -o $domain/nuclei_result.txt

echo "--------------------------------------------------------------------"

cat $domain/recon/live_subdomains.txt | waybackurls | anew $domain/wayback_urls.txt
cat $domain/wayback_urls.txt | egrep -v '\.css|\.png|\.jpeg|\.jpg|\.svg|\.gif|\.woff|\.ttf|\.ico' | sed 's/:80//g;s/:443//g' | urldedupe -s | anew $domain/recon/wayback_results.txt

rm $domain/wayback_urls.txt

echo "--------------------------------------------------------------------"

ffuf -c -u "FUZZ" -w $domain/recon/wayback_results.txt -mc 200 -of csv -o $domain/valid_urls.txt
cat $domain/valid_urls.txt | grep http | awk -F "," '{print $1}' | anew $domain/recon/valid_urls.txt

rm $domain/valid_urls.txt

echo "--------------------------------------------------------------------"

cat $domain/recon/wayback_results.txt | unfurl --unique paths | anew $domain/recon/site_wordlist.txt
cat $domain/recon/wayback_results.txt | unfurl --unique  domains | anew $domain/recon/site_domains.txt


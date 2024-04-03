#!/bin/bash

#curl -o cnip1.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
#curl -o cnip2.txt https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china.txt
#curl -o cnsite.txt https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
#curl -o nocnsite.txt https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt
curl -o ad.txt https://raw.githubusercontent.com/Mujinniao/list/main/domain.txt



#cat cnip*.txt | sort -u > cn_ip_cidr.txt

#rm cnip1.txt cnip2.txt



#sed -i -e 's/^server=\///' -e 's/\/114.114.114.114//' -e '/^#/d' -e '/^$/d' cnsite.txt

#sort -u cnsite.txt > cn_domain.txt

#sed 's/^/./' cnsite.txt > cn_domain_suffix.txt

#rm cnsite.txt



#base64 -d nocnsite.txt > temp.txt && mv temp.txt nocnsite.txt

#sed -i -e '/^\[/d' -e '/^!/d' -e '/^$/d' nocnsite.txt

#grep '^@@' nocnsite.txt > white.txt && sed -i -e '/^@@/d' -e '/^$/d' nocnsite.txt

#sed -i 's/^@@//' white.txt

#sort nocnsite.txt -o nocnsite.txt

#sort white.txt -o white.txt

#comm -23 nocnsite.txt white.txt > temp.txt && mv temp.txt nocnsite.txt

#sed -i -e 's/^||//' -e 's/^|//' -e 's/https:\/\///' -e 's/http:\/\///' -e 's/\/.*//' nocnsite.txt

#sed -e '/\*/d' -e '/^$/d' -e '/^[^.]/s/^/./' nocnsite.txt > nocn_domain_suffix.txt

#sed -e '/^\./d' -e '/\*/d' -e '/^$/d' nocnsite.txt > nocn_domain.txt

#grep '\*' nocnsite.txt | sed -e 's/\./\\./g' -e 's/\*/\.\*/g' > nocn_domain_regex.txt

#rm nocnsite.txt white.txt



sed -i -e 's/^0.0.0.0 //' -e 's/^127.0.0.1 //' -e 's/\^.*//' -e 's/^||//' -e 's/|//' ad.txt 

sed -Ei -e '/([0-9]{1,3}\.){2}[0-9]{1,3}/d' ad.txt 

sed -e '/\*/d' ad.txt > ad_domain.txt

sed -e 's/^/./' ad_domain.txt > ad_domain_suffix.txt

grep '\*' ad.txt | sed -e 's/\./\\./g' -e 's/\?/\\?/g' -e 's/\*/\.\*/g' > ad_domain_regex.txt

grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' ad.txt > ad_ip_cidr.txt

rm ad.txt



#jq --slurpfile domain <(cat cn_domain.txt | jq -R .) '.rules[0].domain += $domain' mod.json > temp.json

#jq --slurpfile domain_suffix <(cat cn_domain_suffix.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp.json > temp1.json

#jq --slurpfile ip_cidr <(cat cn_ip_cidr.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' temp1.json > cn.json

#rm cn_ip_cidr.txt cn_domain*.txt temp*.json




#jq --slurpfile domain <(cat nocn_domain.txt | jq -R .) '.rules[0].domain += $domain' mod.json > temp.json

#jq --slurpfile domain_suffix <(cat nocn_domain_suffix.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp.json > temp1.json

#jq --slurpfile domain_regex <(cat nocn_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp1.json > nocn.json

#rm nocn_domain*.txt temp*.json




jq --slurpfile domain <(cat ad_domain.txt | jq -R .) '.rules[0].domain += $domain' mod.json > temp.json

jq --slurpfile domain_suffix <(cat ad_domain_suffix.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp.json > temp1.json

jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp1.json > temp2.json

jq --slurpfile ip_cidr <(cat ad_ip_cidr.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' temp2.json > ad.json

sed -i 's/\\r//g' ad.json

rm ad_ip_cidr.txt ad_domain*.txt temp*.json






tar -xzvf sing-box.tar.gz

#./sing-box-1.8.5-linux-amd64/sing-box rule-set compile --output cn.srs cn.json

#./sing-box-1.8.5-linux-amd64/sing-box rule-set compile --output nocn.srs nocn.json

./sing-box-1.8.5-linux-amd64/sing-box rule-set compile --output ad.srs ad.json

rm -rf sing-box-1.8.5-linux-amd64/ cn.json nocn.json ad.json







#!/bin/bash





curl -o ad.txt https://raw.githubusercontent.com/Mujinniao/list/main/domain.txt




sed -i -E 's/^\|\|//; s/\^$//' ad.txt








#处理domain

#jq --slurpfile domain <(cat cn_domain-s.txt | jq -R .) '.rules[0].domain += $domain' ./tem/domain.json > temp.json

jq --slurpfile domain_suffix <(cat ad.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' ./tem/domain.json > ad.json

#jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp1.json > temp2.json

rm ad.txt

mv ad.json ./out/ad.json


chmod +x ./bin/sing-box

./bin/sing-box rule-set compile --output ./out/ad.srs ./out/ad.json














#!/bin/bash

curl -o cnip1.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
curl -o cnip2.txt https://raw.githubusercontent.com/misakaio/chnroutes2/refs/heads/master/chnroutes.txt
curl -o cnip3.txt https://raw.githubusercontent.com/gaoyifan/china-operator-ip/refs/heads/ip-lists/china.txt
#curl -o nocnsite.txt https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt


curl -o cnsite1.txt https://raw.githubusercontent.com/v2fly/domain-list-community/refs/heads/release/cn.txt
curl -o cnsite2.txt https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/refs/heads/master/accelerated-domains.china.conf



curl -o ad.txt https://raw.githubusercontent.com/Mujinniao/list/main/domain.txt

#处理ip
#去除#开头行
sed -i '/^#/d' cnip2.txt
#合并去重
cat cnip*.txt | sort -u > cn_ip.txt

rm cnip*.txt



#处理site1
#删除带@ads @!cn的行，去除行尾:@cn字符串
sed -i -e '/@ads/d' -e '/@!cn/d' -e 's/\:@cn//' cnsite1.txt
#按全名 后缀 正则提取site1
grep '^domain' cnsite1.txt > cnsite1_suffix.txt
grep '^full' cnsite1.txt > cnsite1_domain.txt
grep '^regexp' cnsite1.txt > cnsite1_regexp.txt
#处理site1
sed -i 's/domain://' cnsite1_suffix.txt
sed -i 's/full://' cnsite1_domain.txt
sed -i -e 's/regexp://' -e 's/\$//' cnsite1_regexp.txt


#处理site2
sed -e 's/^server=\///' -e 's/\/114.114.114.114//' -e '/^#/d' -e '/^$/d' cnsite2.txt > cnsite2_suffix.txt
#合并去重后缀
cat cnsite2_suffix.txt cnsite1_suffix.txt | sort -u > cnsite_suffix.txt

#合并去重全名(sing-box)
cat cnsite_suffix.txt cnsite1_domain.txt | sort -u > cn_domain-s.txt

mv cnsite1_domain.txt cnsite1_domain-m.txt

#处理符合sing-box的后缀规则
sed 's/^/\./g' cnsite_suffix.txt > cn_domain_suffix-s.txt

#处理符合mihomo的后缀规则
sed 's/^/\+./g' cnsite_suffix.txt > cn_domain_suffix-m.txt
#合并
cat cn_domain_suffix-m.txt  cnsite1_domain-m.txt > cn_domain-m.txt

rm cnsite1.txt cnsite2.txt cnsite1_suffix.txt cnsite2_suffix.txt cnsite_suffix.txt cnsite1_regexp.txt cnsite1_domain-m.txt cn_domain_suffix-m.txt





# cn_domain-s.txt cn_domain_suffix-s.txt  cn_domain-m.txt cn_ip.txt

#处理domain

jq --slurpfile domain <(cat cn_domain-s.txt | jq -R .) '.rules[0].domain += $domain' ./tem/domain.json > temp.json

jq --slurpfile domain_suffix <(cat cn_domain_suffix-s.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp.json > cn_domain-s.json

#jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp1.json > temp2.json

rm temp.json

#处理ip


jq --slurpfile ip_cidr <(cat cn_ip.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' ./tem/ip.json > cn_ip-s.json


#处理all
jq --slurpfile domain <(cat cn_domain-s.txt | jq -R .) '.rules[0].domain += $domain' ./tem/all.json > temp.json

jq --slurpfile domain_suffix <(cat cn_domain_suffix-s.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp.json > temp1.json

#jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp1.json > temp2.json

jq --slurpfile ip_cidr <(cat cn_ip.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' temp1.json > cn_all-s.json

rm temp*.json cn_domain-s.txt cn_domain_suffix-s.txt

mv cn_domain-s.json ./out/s/cn_domain.json
mv cn_ip-s.json ./out/s/cn_ip.json
mv cn_all-s.json ./out/s/cn_all.json

chmod +x ./bin/sing-box

./bin/sing-box rule-set compile --output ./out/s/cn_domain.srs ./out/s/cn_domain.json
./bin/sing-box rule-set compile --output ./out/s/cn_ip.srs ./out/s/cn_ip.json
./bin/sing-box rule-set compile --output ./out/s/cn_all.srs ./out/s/cn_all.json






mv cn_domain-m.txt ./out/m/cn_domain.txt
mv cn_ip.txt ./out/m/cn_ip.txt
chmod +x ./bin/mihomo

./bin/mihomo convert-ruleset domain text ./out/m/cn_domain.txt ./out/m/cn_domain.mrs
./bin/mihomo convert-ruleset ipcidr text ./out/m/cn_ip.txt ./out/m/cn_ip.txt.mrs








sed -i -e 's/^0.0.0.0 //' -e 's/^127.0.0.1 //' -e 's/\^.*//' -e 's/^||//' -e 's/|//' ad.txt 

sed -Ei -e '/([0-9]{1,3}\.){2}[0-9]{1,3}/d' ad.txt 

sed -e '/\*/d' ad.txt > ad_domain.txt

#符合sing-box
sed -e 's/^/./' ad_domain.txt > ad_domain_suffix-s.txt
#处理符合mihomo的后缀规则
sed 's/^/\+./g' ad_domain.txt > ad_domain_suffix-m.txt


#grep '\*' ad.txt | sed -e 's/\./\\./g' -e 's/\?/\\?/g' -e 's/\*/\.\*/g' > ad_domain_regex.txt

#grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' ad.txt > ad_ip_cidr.txt


rm ad.txt




#jq --slurpfile domain <(cat ad_domain.txt | jq -R .) '.rules[0].domain += $domain' ./tem/all.json > temp.json

#jq --slurpfile domain_suffix <(cat ad_domain_suffix.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp.json > temp1.json

#jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp1.json > temp2.json

#jq --slurpfile ip_cidr <(cat ad_ip_cidr.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' temp2.json > ad_all.json



jq --slurpfile domain <(cat ad_domain.txt | jq -R .) '.rules[0].domain += $domain' ./tem/domain.json > temp3.json

jq --slurpfile domain_suffix <(cat ad_domain_suffix-s.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp3.json > ad_domain-s.json

#jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp4.json > ad_domain.json


#jq --slurpfile ip_cidr <(cat ad_ip_cidr.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' temp5.json > ad_ip.json



#sed -i 's/\\r//g' ad_all.json
#sed -i 's/\\r//g' ad_domain.json
#sed -i 's/\\r//g' ad_ip.json
rm ad_domain.txt ad_domain_suffix-s.txt temp*.json

mv ad_domain-s.json ./out/s/ad_domain.json

chmod +x ./bin/sing-box

./bin/sing-box rule-set compile --output ./out/s/ad_domain.srs ./out/s/ad_domain.json
./bin/sing-box rule-set compile --output ./out/s/nocn.srs ./source/nocn.json





mv ad_domain_suffix-m.txt ./out/m/ad_domain.txt

chmod +x ./bin/mihomo

./bin/mihomo convert-ruleset domain text ./out/m/ad_domain.txt ./out/m/ad_domain.mrs






# tar -xzvf sing-box.tar.gz

#./sing-box-1.8.5-linux-amd64/sing-box rule-set compile --output cn.srs cn.json

#./sing-box-1.8.5-linux-amd64/sing-box rule-set compile --output nocn.srs nocn.json



#./bin/sing-box rule-set compile --output dns.srs ./source/dns.json



#./bin/sing-box rule-set compile --output ./out/ad_ip.srs ./out/ad_ip.json

#./bin/sing-box rule-set compile --output ./out/ad_all.srs ./out/ad_all.json



# rm ad.json







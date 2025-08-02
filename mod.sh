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
sed -i -e 's/^server=\///' -e 's/\/114.114.114.114//' -e '/^#/d' -e '/^$/d' cnsite2.txt
#合并去重后缀
cat cnsite2.txt cnsite1_suffix.txt | sort -u > cnsite_suffix.txt
#合并去重全名
cat cnsite_suffix.txt cnsite1_domain.txt | sort -u > cn_domain.txt
#处理符合sing-box的后缀规则
sed 's/^/\.&/g' cnsite_suffix.txt > cn_domain_suffix.txt

rm cnsite1.txt cnsite2.txt cnsite1_domain.txt cnsite1_suffix.txt cnsite_suffix.txt



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



jq --slurpfile domain <(cat ad_domain.txt | jq -R .) '.rules[0].domain += $domain' ./tem/all.json > temp.json

jq --slurpfile domain_suffix <(cat ad_domain_suffix.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp.json > temp1.json

jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp1.json > temp2.json

jq --slurpfile ip_cidr <(cat ad_ip_cidr.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' temp2.json > ad_all.json



jq --slurpfile domain <(cat ad_domain.txt | jq -R .) '.rules[0].domain += $domain' ./tem/domain.json > temp3.json

jq --slurpfile domain_suffix <(cat ad_domain_suffix.txt | jq -R .) '.rules[0].domain_suffix += $domain_suffix' temp3.json > temp4.json

jq --slurpfile domain_regex <(cat ad_domain_regex.txt | jq -R .) '.rules[0].domain_regex += $domain_regex' temp4.json > ad_domain.json



jq --slurpfile ip_cidr <(cat ad_ip_cidr.txt | jq -R .) '.rules[0].ip_cidr += $ip_cidr' temp5.json > ad_ip.json



sed -i 's/\\r//g' ad_all.json
sed -i 's/\\r//g' ad_domain.json
sed -i 's/\\r//g' ad_ip.json



mv -f ad_all.json ./out/ad_all.json
mv -f ad_domain.json ./out/ad_domain.json
mv -f ad_ip.json ./out/ad_ip.json



rm ad_ip_cidr.txt ad_domain*.txt temp*.json



chmod +x ./bin/sing-box



# tar -xzvf sing-box.tar.gz

#./sing-box-1.8.5-linux-amd64/sing-box rule-set compile --output cn.srs cn.json

#./sing-box-1.8.5-linux-amd64/sing-box rule-set compile --output nocn.srs nocn.json

./bin/sing-box rule-set compile --output nocn.srs ./source/nocn.json

./bin/sing-box rule-set compile --output dns.srs ./source/dns.json

./bin/sing-box rule-set compile --output ./out/ad_domain.srs ./out/ad_domain.json

./bin/sing-box rule-set compile --output ./out/ad_ip.srs ./out/ad_ip.json

./bin/sing-box rule-set compile --output ./out/ad_all.srs ./out/ad_all.json



# rm ad.json







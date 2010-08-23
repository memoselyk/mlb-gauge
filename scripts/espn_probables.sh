#!/bin/sh

# Data fetched from 
#  * http://espn.go.com/mlb/probables/_/date/20100822

#FIXME: Get date from cmd_line
#TODO: Download css
date="20100822"

base_url="http://espn.go.com/mlb/probables/_/date/"

drop_base="${HOME}/mlb/cache"
drop_probable="${drop_base}/espn/probables/$(date --date $date "+%b-%Y")"
drop_players="${drop_base}/espn/players"
players_base="${drop_players}/playerId_"
drop_file="${drop_probable}/$(date --date $date "+%d").htm"

[ -e $drop_probable ] || mkdir -v -p $drop_probable
[ -e $drop_players ] || mkdir -v -p $drop_players

#Fetch probables
wget -O "$drop_file" "${base_url}${date}"

#Remove unneeded tags TODO

#Fetch players links & replace links
grep -o '<a href[^>]*>[^<]*....' "$drop_file"|grep 'mlb/players/profile?playerId='|sed 's!">.*!!;s!^.*href="!!'|while read hlink
do
    dlink="http://espn.go.com${hlink}"
    play_file="${players_base}$(echo "$hlink"|sed 's!.*=!!').htm"
    wget -O "$play_file" "$dlink"
    sed -i 's!'"$hlink"'!../../players/'$(basename "$play_file")'!' "$drop_file"
done

#Fix stylesheets

# grep stylesheet -R ./|sed 's!.*href="!!;s!".*!!'|sort|uniq|grep -v combiner|while read css;do wget -O "$(basename "$css")" "$css";done
# sed -i 's!http://a.espncdn.com/prod/styles/modules/master_tables_09.r3.css!../../master_tables_09.r3.css!' probables/Aug-2010/22.htm
# grep stylesheet -R ./players/ |sed 's!.*href="!!;s!".*!!'|sort|uniq|grep -v combiner|while read css;do find ./players -type f|while read htm;do sed -i 's!'"$css"'!../'$(basename "$css")'!' "$htm";done;done

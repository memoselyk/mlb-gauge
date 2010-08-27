#/bin/sh

 # TODO parse results if game is final
 # FIXME probable not parsed properly : probable_name_display_first_last: 'Sean O\'Sullivan', probable: 'O\'Sullivan',

#wget -q -O - 'http://mlb.mlb.com/mlb/schedule/?tcid=mm_mlb_schedule' > /tmp/ParseMLBSchedule.htm
#date  --date "1970-01-01 $(echo " 1282443000000 /1000 - 6*3600"|bc) sec"

# Schedule is fetched from http://mlb.mlb.com/components/schedule/schedule_YYYMMDD.json ex http://mlb.mlb.com/components/schedule/schedule_20100818.json
# parsing is based on http://mlb.mlb.com/scripts/schedule/scheduleapp.js

[ $# -eq 1 ] || { echo -n "Usage:\n\t$0 <date>\n"; exit 1; }

cat $1 | awk --field-separator \' '

function fluch() {
	printf "%s ; %s ; %s ; %s ; %s ; %s ; %s\n",
		game_status,
		game_date,
		team["ROAD"],
		team["HOME"],
		game_time,
		probable["ROAD"],
		probable["HOME"]
}

function update_team(){
	team[ind] = sprintf("%s %s", team_code[ind], team_name[ind]);
}

function update_probable(){
	if(length(probable_last[ind]) == 0 )
		probable[ind] = "TBD";
	else
		probable[ind] = sprintf("%s (%s, %s)", probable_name_display_first_last[ind], probable_stat[ind], probable_era[ind]);
}

BEGIN{
	game_status = "Game Status";
	game_date = "Game Date";
	team["ROAD"] = "Away";
	team["HOME"] = "Home";
	game_time = "Time (CDT)";
	probable["ROAD"] = "Away probable";
	probable["HOME"] = "Home probable";
}

/^\[\{/{ fluch(); }
/^\}\]/{ fluch(); }
/^\}, \{/{ fluch(); }

/game_status:/{
	game_status = "N/A"
	switch( $2 ) {
		case "T" : # T Suspended
			game_status = "Suspended";
			break;
		case "U" : # U Suspended
			game_status = "Suspended";
			break;
		case "S" : # S Scheduled
			game_status = "Scheduled";
			break;
		case "P" : # P Pre-game
			game_status = "Pre-game";
			break;
		case "I" : # I In Progress
			game_status = "In Progress";
			break;
		case "D" : # D Postponed
			game_status = "Postponed";
			break;
		case "O" : # O Game Over
			game_status = "Game Over";
			break;
		case "F" : # F Final
			game_status = "Final";
			break;
		case "C" : # C Cancelled
			game_status = "Cancelled";
			break;
		case "Q" : # Q Forfeit: Game Over
			game_status = "Forfeit: Game Over";
			break;
		case "R" : # R Forfeit: Final
			game_status = "Forfeit: Final";
			break;
	}
}
#/game_type:/{ print $2 } #Dont know how to handle it (May indicate if game is season, pre or post
/game_time_is_tbd:/{
	sub( /[a-z]+_[a-z_]+/ , "", $1 );
	gsub( /[:, \t]/ , "", $1 );
	is_tbd = $1;
}
/game_time:/{
	if( is_tbd == "false" ){
		game_date = strftime("%Y-%m-%d", $2/1000);
		game_time = strftime("%I:%M %p", $2/1000);
	} else {
		game_date = "TBD"
		game_time = "TBD"
	}
}

/home: \{/{ ind = "HOME" }
/away: \{/{ ind = "ROAD" }

/full:/{ team_name[ind] = $2; update_team(); }
/display_code:/{ team_code[ind] = $2; update_team(); }
/probable:/{ probable_last[ind] = $2; update_probable(); }
/probable_era:/{ probable_era[ind] = $2; update_probable(); }
/probable_stat:/{ probable_stat[ind] = $2; update_probable(); }
/probable_name_display_first_last:/{ probable_name_display_first_last[ind] = $2; update_probable(); }
'

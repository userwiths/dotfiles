setxkbmap -layout us,bg;
setxkbmap -option "grp:shift_alt_toggle,grp_led:scroll" us,bg -variant ,phonetic;
date -s "$(curl "http://worldtimeapi.org/api/ip" | jq '.datetime' | awk -F 'T' '{print $2}'|awk -F '.' '{print $1}')";

systemctl restart iwd
pulseaudio --daemonize=true
pavucontrol &
teams-for-linux --no-sandbox &
flameshot &
firefox https://www.discord.com/app \
	 https://belugait.slack.com \
	 https://start.atlassian.com \
         https://github.com;
firefox --private-window https://github.com/login;
#if [ $(xrandr --listmonitors | wc -l) -eq 2 ]; then
#	xrandr --output eDP-1 --auto --output HDMI-1-0 --auto ; xrandr --output eDP-1 --right-of HDMI-1-0;
#fi;
#code --no-sandbox &
thunar --daemonize &;
obs &;

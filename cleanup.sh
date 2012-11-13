rm -rf /data
rm -f /etc/nginx/conf.d/webgui8.conf
rm -f /etc/rc.d/*/*webgui8
killall starman
mysql --user=root --password=Nyklm6 -e 'drop database www_example_com;'
# apt-get remove -y percona-server-server-5.5

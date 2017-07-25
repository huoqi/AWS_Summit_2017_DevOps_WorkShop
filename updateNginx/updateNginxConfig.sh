#! /bin/bash
service nginx stop
rm -f "/etc/nginx/nginx.conf"	
rm -rf "/etc/nginx/conf.d/"
aws s3 cp s3://config.xinjian.io/nginx/nginx.conf "/etc/nginx/nginx.conf"
aws s3 cp s3://config.xinjian.io/nginx/conf.d/ "/etc/nginx/conf.d/" --recursive
service nginx start
log="`date +'%Y-%m-%d %H:%M:%S'` updated nginx config. done!"
echo $log
echo $log >> deploy.log

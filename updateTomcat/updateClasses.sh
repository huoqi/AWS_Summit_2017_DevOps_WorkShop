#! /bin/bash

service tomcat8 stop
cp -R /home/ec2-user/target/classes/ /home/ec2-user/webapps/ROOT/WEB-INF/
service tomcat8 start
echo Done!


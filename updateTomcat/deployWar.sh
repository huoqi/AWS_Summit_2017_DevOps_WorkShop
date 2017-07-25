#! /bin/bash

if [[ $# -eq 0 ]]; then
	warFile="/home/ec2-user/target/summit-web.war"
elif [[ $# -eq 1 ]]; then
	warFile="$1"
else 
	echo "Parameter Error!"
	exit 1
fi

if [[ -f "$warFile" ]]; then
	service tomcat8 stop
	rm -f "/usr/share/tomcat8/webapps/ROOT.war"
	rm -rf "/usr/share/tomcat8/webapps/ROOT"
	cp "$warFile" "/usr/share/tomcat8/webapps/ROOT.war"
	service tomcat8 start
	cp "$warFile" "${warFile%'.war'}_`date +'%Y-%m-%d_%H:%M:%S'`.war"
	echo
	echo Done!	
else
    echo "No file: $warFile!"
fi


#! /bin/bash
if [[ $# -eq 0 ]]; then
    WAR=ROOT.war
    TARGET=ROOT.war
elif [[ $# -eq 1 ]]; then
    WAR=$1
    TARGET=ROOT.war
elif [[ $# -eq 2 ]]; then
    WAR=$1
    TARGET=$2
else 
    echo "Parameter Error!"
    exit 1
fi

WAR=`echo $WAR | awk -F '.war' '{print $1}'`
TARGET=`echo $TARGET | awk -F '.war' '{print $1}'`
LOG="/home/ec2-user/updateTomcat/deploy.log"

echo "`date +'%Y-%m-%d %H:%M:%S'` sotpping tomcat..." >>$LOG
service tomcat8 stop
rm -f "/usr/share/tomcat8/webapps/$TARGET.war"	
rm -rf "/usr/share/tomcat8/webapps/$TARGET"
aws s3 cp s3://config.xinjian.io/war/"$WAR".war "/usr/share/tomcat8/webapps/$TARGET.war"

echo "`date +'%Y-%m-%d %H:%M:%S'` starting tomcat..." >>$LOG
service tomcat8 start
echo "`date +'%Y-%m-%d %H:%M:%S'` Deploy $TARGET.war from S3 done."  >>$LOG	

exit 0
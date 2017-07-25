#! /bin/bash

if [[ $# -eq 0 ]]; then
    BRANCH=master
    TARGET=ROOT.war
elif [[ $# -eq 1 ]]; then
    BRANCH=$1
    TARGET=ROOT.war
elif [[ $# -eq 2 ]]; then
    BRANCH=$1
    TARGET=$2
else 
    echo "Parameter Error!"
    exit 1
fi
TARGET=`echo $TARGET | awk -F '.' '{print $1}'`

cd /home/ec2-user/web
git checkout $BRANCH
git pull
mvn clean install

S3_Prefix="s3://config.xinjian.io/war/"
S3_War=$S3_Prefix"$TARGET".war
S3_WarBack=$S3_Prefix"$TARGET""_`date +'%Y-%m-%d_%H:%M:%S'`.war"
warFile="/home/ec2-user/web/target/summit-devops.war"

aws s3 cp $warFile $S3_WarBack
aws s3 rm $S3_War
aws s3 cp $S3_WarBack $S3_War

echo "upload done."


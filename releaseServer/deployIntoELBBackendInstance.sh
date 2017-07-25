#/bin/bash
# deployIntoELBBackendInstance.sh

succeed_instances=""
failed_instances=""
ELB_NAME=""
DEPLOY_COMMAND="sudo -s sh /home/ec2-user/updateTomcat/deployFromS3.sh"

function usage()
{
	echo "Usage: $0 [Option] <parameters>"
	echo "Options:"
	echo "  -E	ELB name"
	echo "  -c	Deployment command. Default: \"$DEPLOY_COMMAND\""
}

function addSuccessInstance()
{
	if [[ $# -ne 1 ]]; then
		return 1
	fi

	#add this intance to "succeed instances list" if get private ip
	if [[ -z "$succeed_instances" ]]; then
		succeed_instances=$instance
	else
		succeed_instances="$succeed_instances",\ "$instance"
	fi
}

function addFailedInstance()
{
	if [[ $# -ne 1 ]]; then
		return 1
	fi
	
	#add this intance to "fialed instance list" if can't get private ip
	if [[ -z "$failed_instances" ]]; then
		failed_instances=$instance
	else
		failed_instances="$failed_instances",\ "$instance"
	fi
}

function deploy()
{
	if [[ $# -ne 1 ]]; then
		return 1
	fi

	privateIp=$1
	# ssh in and deploy on this instance
	echo Deploying to $privateIp 
	ssh $privateIp "$DEPLOY_COMMAND"
	# ssh $privateIp echo deploying...
	for (( i = 0; i < 6; i++ )); do
		echo -n Please wait for retarting tomcat 
		for (( j = 0; j < 10; j++ )); do
			echo -n .
			sleep 1s
		done
		echo .

		testLineNum=`curl -s $privateIp:8080 | grep html | wc -l`
		if [[ $testLineNum -gt 0 ]]; then
			echo tomcat retarts successfully.
			break
		fi
	done
}

#main
while getopts "E:c:" arg
do
	case $arg in
		E )
			ELB_NAME=$OPTARG
			;;
		c ) 
			DEPLOY_COMMAND=$OPTARG
			;;
		? )	
			echo "Unknown argument."
			usage
			exit 1
			;;
	esac
done

if [[ -z "$ELB_NAME" ]]; then
	echo "$0: missing elb name"
	usage
	exit 1
fi
# verify if exist this ELB
verifyELB=`aws elb describe-load-balancers --load-balancer-name $ELB_NAME | grep LoadBalancerName | awk -F '"' '{print $4}'`
if [[ "$verifyELB"x != "$ELB_NAME"x ]]; then
	echo Cannot find Load Balancer $ELB_NAME
	exit 1
fi
# go on if exist this elb
for instance in `aws elb describe-instance-health --load-balancer-name $ELB_NAME | grep InstanceId | awk -F '"' '{print $4}'` ; do
	echo $instance is in progress...

	#loop getting until get private ip
	privateIp=""
	for ip in `aws ec2 describe-instances --instance-ids $instance | grep PrivateIpAddress | awk -F '"' '{print $4}'` ; do
		if [[ -n "$ip" ]]; then
			privateIp=$ip
			break
		fi
	done

	if [[ -z "$privateIp" ]]; then
		addFailedInstance $instance
	else
		#deregister this instance from elb
		aws elb deregister-instances-from-load-balancer --load-balancer-name $ELB_NAME --instances $instance >/dev/null 2>&1
		echo -n Please waitting for deregistering $instance from elb $ELB_NAME
		for (( i = 0; i < 20; i++ )); do
			sleep 5s
			echo -n .
			outservice=`aws elb describe-instance-health --load-balancer-name $ELB_NAME --instances $instance | grep OutOfService | wc -l`
			if [[ $outservice -eq 1 ]]; then
				echo
				echo $instance has been deregistered from elb $ELB_NAME
				deploy $privateIp
				#register this instance with elb
				aws elb register-instances-with-load-balancer --load-balancer-name $ELB_NAME --instances $instance >/dev/null 2>&1
				echo -n Please wait for registering $instance with elb $ELB_NAME
				for (( j = 0; j < 20; j++ )); do
					sleep 6s
					echo -n .
					inservice=`aws elb describe-instance-health --load-balancer-name $ELB_NAME --instances $instance | grep InService | wc -l`
					if [[ $inservice -eq 1 ]]; then
						echo
						echo $instance has been registered with elb $ELB_NAME
						addSuccessInstance $instance
						break
					fi
					if [[ $j -ge 19 ]]; then
						addFailedInstance $instance
					fi
				done
				echo
				break
			elif [[ $i -ge 19 ]]; then
				echo 
				echo Deregister $instance time out. Process the next
				addFailedInstance $instance
				echo
				continue
			fi
		done
	fi
done

echo 
echo succeed instances: $succeed_instances
echo failed instances: $failed_instances



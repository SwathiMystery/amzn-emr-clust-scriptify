#!/bin/bash
# Launch cluster and add step and terminate it when in waiting state.

# No. of slave nodes - CR
COUNT="3"
# s3 bucket log folder - CR
LOG_URI="s3://anon-logs/emr/"
# Cluster Name  - CR
CLUSTER_NAME="Simpsons"

JOBFLOW_ID=`/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce --create --alive --name $CLUSTER_NAME \
		--master-instance-type c1.xlarge --slave-instance-type c1.xlarge  --num-instances $COUNT \
			--ami-version 3.0.3  --key-pair hadoopkey --plain-output --debug --log-uri $LOG_URI \
				--set-visible-to-all-users true`
echo "Launched --jobflow $JOBFLOW_ID"
echo "Cluster is setting up ... "

waiting="1";
time while [ "$waiting" != "0" ]; do
sleep 3
/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce --describe $JOBFLOW_ID |grep "State.*WAITING" > /dev/null
waiting=$?
done

echo "Cluster Setup Done. Now in WAITING state ..."

echo "Launching Job..."
# Launch your job from EMR CLI - CR
/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce  -j $JOBFLOW_ID \
		--jar s3://anon-emr/jars/anon-0.0.1.jar \
		        --main-class com.anon.stuffs.MainClass  \
				    --arg arg1 \
					 --arg arg2 \

running="1";
time while [ "$running" != "0" ]; do
sleep 3
/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce --describe $JOBFLOW_ID |grep "State.*RUNNING" > /dev/null
running=$?
done
echo "Job is in RUNNING State ..."

waiting="1";
time while [ "$waiting" != "0" ]; do
sleep 3
/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce --describe $JOBFLOW_ID |grep "State.*WAITING" > /dev/null
waiting=$?
done
echo "Job Executed. Checking STATUS ..."

STATUS=`/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce --list -j $JOBFLOW_ID | tail -n 1 | awk {'print $1'}`
if [ "$STATUS" == "COMPLETED" ];
then         
		echo "Job COMPLETED!"
			/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce --terminate  $JOBFLOW_ID
				echo "Terminated --jobflow $JOBFLOW_ID."
					exit 0
				fi 
				if [ "$STATUS" == "FAILED" ];
				then
						echo "Job FAILED!"
							/usr/bin/ruby /home/ubuntu/elastic-mapreduce-cli/elastic-mapreduce --terminate  $JOBFLOW_ID
								echo "Terminated --jobflow $JOBFLOW_ID."
									exit 113
								fi

#!/bin/bash
# ec2-describe-snapshots --hide-tags --region us-west-1 -F volume-id=vol-xxxxxx
# output:
# SNAPSHOT snap-xxxxxx vol-xxxxxx completed 2013-09-19T23:24:26+0000 100% 519544898336 25 mysql 5.6
export PATH=$PATH:/opt/aws/bin
RET=0
 
usage() {
 echo -e "$0\t  ";
 echo -e "$0\tus-west-1 vol-12345 31";
 exit 1;
}
 
makeSnapshot() {
 local r=$1, vol=$2
 echo "Creating new snapshot for volume $vol"
 ec2-create-snapshot --region $region $vol -d "Backup $(date +'%Y%m%d%H%M%S') of $vol"
 export RET=$?
}
 
deleteSnapshot() {
 local r=$1, snap=$2
 echo "Deleting oldest snapshot $snap"
 ec2-delete-snapshot --region $region $snap
 export RET=$?
}
 
region=$1
volume=$2
test -z $1 && usage
test -z $2 && usage
test -z $3 && backlog=5 || backlog=$3
test -z $AWS_CREDENTIAL_FILE && echo "AWS_CREDENTIAL_FILE not set"
snaps=( $( ec2-describe-snapshots --hide-tags --region $region -F volume-id=$volume | egrep -o 'snap-[0-9A-Za-z]+' ) )
nosnaps=${#snaps[@]}
 
if [ $nosnaps -lt $backlog ]; then
 makeSnapshot $region $volume
 test $RET -gt 0 && exit 1 || exit 0
else
 lastsnap=$( let $nosnaps-1 )
 oldestTS=$( ec2-describe-snapshots --hide-tags --region $region -F
 "volume-id=$volume" | egrep -o "Backup [0-9]+ of" | egrep -o '[0-9]+' | sort | head -n1 )
 snap=$( ec2-describe-snapshots --hide-tags --region $region -F "volume-id=$volume" -F "description=*${oldestTS}*" | egrep -o 'snap-[0-9A-Za-z]+' );
 deleteSnapshot $region ${snap}
 test $RET -gt 0 && exit 1
 makeSnapshot $region $volume
 test $RET -gt 0 && exit 1 || exit 0
fi;



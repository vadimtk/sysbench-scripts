MONGODIR=/opt/vadim/bin/percona-server-mongodb-3.2.6-1.0/
DATADIR=/data/sam/mongorocks
REMOTEHOST=172.16.0.3

startmongo(){
  ssh -n root@$REMOTEHOST "sync"
  ssh -n root@$REMOTEHOST "sysctl -q -w vm.drop_caches=3"
  ssh -n root@$REMOTEHOST "echo 3 > /proc/sys/vm/drop_caches"
  ssh -n root@$REMOTEHOST "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
#  ssh -n -f root@$REMOTEHOST "numactl --interleave=all $MONGODIR/bin/mongod --dbpath=$DATADIR --wiredTigerCacheSizeGB=${BP} > /dev/null 2>&1 &"
  ssh -n -f root@$REMOTEHOST "numactl --interleave=all $MONGODIR/bin/mongod --dbpath=$DATADIR --storageEngine=rocksdb --config=$MONGODIR/bin/rocks.conf --rocksdbCacheSizeGB=${BP} >> $DATADIR/output.log 2>&1 &"

#  cd $MONGODIR
#  sync
#  sysctl -q -w vm.drop_caches=3
#  echo 3 > /proc/sys/vm/drop_caches
#  echo never > /sys/kernel/mm/transparent_hugepage/enabled
#  numactl --interleave=all bin/mongod --dbpath=$DATADIR --wiredTigerCacheSizeGB=${BP} 
#ENDSSH
  #numactl --interleave=all bin/mongod --dbpath=$DATADIR --storageEngine=rocksdb --config=bin/rocks.conf --rocksdbCacheSizeGB=${BP}
}

shutdownmongo(){
  ssh root@$REMOTEHOST <<ENDSSH
  echo "Shutting mongod down..."
  $MONGODIR/bin/mongod --dbpath=$DATADIR --shutdown
ENDSSH
#  $MONGODIR/bin/mongo --eval "db.getSiblingDB('admin').shutdownServer()"

pidm=$(ssh root@$REMOTEHOST pidof mongod)
echo "MongoDB PID: $pidm"
  while  [ ! -z "$pidm" ];
  do
    echo "process exists..."
    sleep 60
    pidm=$(ssh root@$REMOTEHOST pidof mongod)
  done
echo "MongoDB should be down"
#echo "Removing lock file"
#ssh root@$REMOTEHOST <<ENDSSH
#  rm -f $MONGODIR/mongod.lock
#ENDSSH

}

waitmongo(){
        set +e
  ssh root@$REMOTEHOST <<ENDSSH

        while true;
        do
                $MONGODIR/bin/mongo --eval "printjson(db.serverStatus())"

                if [ "$?" -eq 0 ]
                then
                        break
                fi

                sleep 30

                echo -n "."
        done
        $MONGODIR/bin/mongo --eval "db.setProfilingLevel(0, 100000)"
ENDSSH
pidm=$(ssh root@$REMOTEHOST pidof mongod)
echo "MongoDB PID: $pidm"
ssh root@$REMOTEHOST <<ENDSSH
        cgcreate -g memory:DBLimitedGroup
        echo $(( $BP * 2 ))G > /sys/fs/cgroup/memory/DBLimitedGroup/memory.limit_in_bytes
        cgclassify -g memory:DBLimitedGroup $pidm
ENDSSH
        set -e
}

initialstat(){
  $MONGODIR/bin/mysqladmin variables > $OUTDIR/mysqlvariables.txt
  cp $CONFIG $OUTDIR
  cp config.sh $OUTDIR
  cp $0 $OUTDIR
}

collect_mysql_stats(){
  $MONGODIR/bin/mysqladmin ext -i10 > $OUTDIR/mysqladminext.txt &
  PIDMONGOSTAT=$!
}
collect_dstat_stats(){
  dstat --output=$OUTDIR/dstat.txt 10 > $OUTDIR/dstat.out &
  PIDDSTATSTAT=$!
}

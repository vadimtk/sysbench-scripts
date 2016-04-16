HOST="--mysql-socket=/tmp/mysql.sock"
MYSQLDIR=/opt/vadim/ps/mysql-5.7.12-linux-glibc2.5-x86_64
DATADIR=/mnt/data/mem/mysql
CONFIG=/etc/my.ps57.cnf

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

startmysql(){
  pushd $MYSQLDIR
  sync
  sysctl -q -w vm.drop_caches=3
  echo 3 > /proc/sys/vm/drop_caches
  LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 numactl --interleave=all bin/mysqld --defaults-file=$CONFIG --datadir=$DATADIR --basedir=$PWD --user=root --ssl=0 --log-error=$DATADIR/error.log --innodb-buffer-pool-size=${BP}G
}

shutdownmysql(){
  echo "Shutting mysqld down..."
  $MYSQLDIR/bin/mysqladmin shutdown -S /tmp/mysql.sock
}

waitmysql(){
        set +e

        while true;
        do
                mysql -Bse "SELECT 1" mysql

                if [ "$?" -eq 0 ]
                then
                        break
                fi

                sleep 30

                echo -n "."
        done
        set -e
}

initialstat(){
  cp $CONFIG $OUTDIR
  cp $0 $OUTDIR
}

collect_mysql_stats(){
  $MYSQLDIR/bin/mysqladmin ext -i10 > $OUTDIR/mysqladminext.txt &
  PIDMYSQLSTAT=$!
}
collect_dstat_stats(){
  dstat --output=$OUTDIR/dstat.txt 10 > $OUTDIR/dstat.out &
  PIDDSTATSTAT=$!
}


# cycle by buffer pool size

for BP in `seq 4 8 170`
do

DB="sb_pareto_20t_50m"

startmysql &
sleep 10
waitmysql

runid="mysql57.BP$BP"

# perform warmup
./sysbench --test=tests/db/oltp.lua --oltp_tables_count=20 --oltp_table_size=50000000 --num-threads=100 $HOST --mysql-user=sbtest --oltp-read-only=on --max-time=300 --max-requests=0 --report-interval=10 --rand-type=pareto --rand-init=on --mysql-db=$DB --mysql-ssl=off run | tee -a res.warmup.ro.txt

for i in 1 2 4 6 10 16 25 38 56 82 120 175 250 360
#for i in 10
do

        OUTDIR=res-OLTP-memory-disk/$runid/thr$i
        mkdir -p $OUTDIR

        # start stats collection
        initialstat
        collect_mysql_stats 
        collect_dstat_stats 

        time=300
        ./sysbench --forced-shutdown=1 --test=tests/db/oltp.lua --oltp_tables_count=20 --oltp_table_size=50000000 --num-threads=${i} $HOST --mysql-user=sbtest --mysql-db=$DB --oltp-read-only=on --max-time=$time --max-requests=0 --report-interval=10 --rand-type=pareto --rand-init=on --mysql-ssl=off run | tee -a $OUTDIR/res.txt

        # kill stats
        set +e
        kill $PIDDSTATSTAT
        kill $PIDMYSQLSTAT
        set -e

        sleep 30
done

shutdownmysql

done

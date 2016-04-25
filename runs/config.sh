HOST="--mysql-socket=/tmp/mysql.sock"
MYSQLDIR=/data/opt/vadim/bin/mysql-5.7.12-linux-glibc2.5-x86_64
DATADIR=/data/flash/tpcc1000
CONFIG=/etc/my.ps57.cnf

startmysql(){
  pushd $MYSQLDIR
  sync
  sysctl -q -w vm.drop_caches=3
  echo "Starting mysqld 0"
  echo 3 > /proc/sys/vm/drop_caches
echo always > /sys/kernel/mm/transparent_hugepage/enabled
echo 120000 > /proc/sys/vm/nr_hugepages
echo 102 > /proc/sys/vm/hugetlb_shm_group
echo 217374182400 > /proc/sys/kernel/shmmax
echo 28214400 > /proc/sys/kernel/shmall
ulimit -l unlimited
  echo "Starting mysqld"
  numactl --interleave=all bin/mysqld --defaults-file=$CONFIG --datadir=$DATADIR --basedir=$PWD --user=root --ssl=0 --large-pages --innodb-buffer-pool-size=${BP}G
}

startmysql1(){
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
  $MYSQLDIR/bin/mysqladmin variables > $OUTDIR/mysqlvariables.txt
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

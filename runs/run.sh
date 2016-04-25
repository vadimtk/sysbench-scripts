source config.sh
DB="sb_pareto_20t_50m"
DIR=res-OLTP-memory-disk-flashmax-hugepages

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

# cycle by buffer pool size

for BP in 180
do

startmysql 
exit
sleep 10
waitmysql

runid="mysql57.BP$BP"

# perform warmup
./sysbench --test=tests/db/oltp.lua --oltp_tables_count=20 --oltp_table_size=50000000 --num-threads=100 $HOST --mysql-user=sbtest --oltp-read-only=on --max-time=300 --max-requests=0 --report-interval=10 --rand-type=pareto --rand-init=on --mysql-db=$DB --mysql-ssl=off run | tee -a res.warmup.ro.txt

for i in 1 2 4 6 10 16 25 38 56 82 120 175 250 360
#for i in 10
do

        OUTDIR=$DIR/$runid/thr$i
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

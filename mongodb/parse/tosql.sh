f="2.csv"
RUNSIG="OLTP-RW-sam863-wt#smblade04-net#"
runparam='{"engine":"wt","storage":"sam863","workload":"RW"}'
rm -f $f
for t in mongowt*
do
for fn in $t/thr*/res.txt
do
res=$(basename "$t")
res=${res#res.} 
fparam=$(dirname $fn)/runparam.json
param=$(cat $fparam | sed 's/"$//' | sed 's/-//g')
addparam=$(echo $param $runparam | jq -c -s add)
bash parsem.sh $fn $RUNSIG$res $f $addparam
echo $t "|" $res "|" $fn "|" $fparam
done
done
#mysql -h10.20.2.4 -e "LOAD DATA LOCAL INFILE '$f' REPLACE INTO TABLE sb_mongo_results FIELDS TERMINATED BY ','" -usbtest  --local-infile=1 benchmarks

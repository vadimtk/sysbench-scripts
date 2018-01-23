#!/usr/bin/perl

#for bp in 100 50 25                                                                                                                 
#do                                                                                                                                  
#for i in 1 2 4 8 16 64 128 256 ; do ./parse.pl respara.db res-OLTP-RW-meltdown-network-4.4.0-112-oltp_read_only/mysql57-pareto.BP${bp}/thr$i/res.txt bp=${bp},kernel=4.4.0-112,workload=oltp_read_only ; done                                                           
#done

use DBI;

sub parse_query {
   my ( $query, $params ) = @_;
   $params ||= {};
   foreach $var ( split( /,/, $query ) ){
     my ( $k, $v ) = split( /=/, $var );
     $params->{$k} = $v;
   }
   return $params;
}

#print join(",",keys %$hh);

my $db = DBI->connect("dbi:SQLite:$ARGV[0]", "", "", {RaiseError => 1, AutoCommit => 0});

$db->do("CREATE TABLE IF NOT EXISTS results (sec INTEGER, threads INTEGER, tps REAL, reads REAL, writes REAL, rt REAL, runid TEXT,bp TEXT,kernel TEXT, workload TEXT)");

my $hh=parse_query($ARGV[2]);
my $keysarg=join(",",keys %$hh);
my $valarg=join(",", map qq('$_'), values %$hh);

open FILE, $ARGV[1];
print "handing ",$ARGV[1],"\n";
my $line;
while ($line=<FILE>){
        if ($line=~/\[\s+(.*?)s\s+\]\sthds:\s(.*?)\stps:\s(.*?)\sqps:\s(.*?)\s\(r\/w\/o:\s(.*?)\/(.*?)\/(.*?)\)\slat\s\(ms\,.*?\):\s(.*?)\s/){
#        print $1,",",$2,",",$3,",",$5,",",$6,",",$8,"\n";
        $db->do("INSERT INTO results (sec,threads,tps,reads,writes,rt,runid,$keysarg) VALUES ($1, $2, $3,$5,$6,$8,'$ARGV[2]',$valarg)");
}
}
$db->do("COMMIT");
$db->disconnect();

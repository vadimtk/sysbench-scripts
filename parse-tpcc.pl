#!/usr/bin/perl

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


my $db = DBI->connect("dbi:SQLite:$ARGV[0]", "", "", {RaiseError => 1, AutoCommit => 0});

$db->do("CREATE TABLE IF NOT EXISTS results (sec INTEGER, threads INTEGER, tps REAL, reads REAL, writes REAL, rt REAL, runid TEXT,bp TEXT, filesystem TEXT, binlog TEXT, syncbinlog TEXT)");

my $hh=parse_query($ARGV[2]);
my $keysarg=join(",",keys %$hh);
my $valarg=join(",", map qq('$_'), values %$hh);

open FILE, $ARGV[1];
print "handing ",$ARGV[1],"\n";
my $line;
while ($line=<FILE>){
        my @ar = split(/,/, $line);
        if ($ar[0] =~ /^\d+$/) {
        $db->do("INSERT INTO results (sec,threads,tps,rt,runid,$keysarg) VALUES ($ar[0],$ar[1], $ar[2], $ar[7],'$ARGV[2]',$valarg)");
        }
}
$db->do("COMMIT");
$db->disconnect();

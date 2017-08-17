#!/usr/bin/perl
use strict;
use warnings;
use Path::Tiny;
use Data::Dumper;
use DBI;
use 5.010;

#Connect to SQLite database
my $driver   = "SQLite";
my $database = "test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 }) or die $DBI::errstr;
   $dbh->do('PRAGMA foreign_keys=ON');
print "Opened database successfully\n";


my $last_family_id = $dbh->prepare('SELECT max(family_id) from family');
$last_family_id->execute();
my $fix = $last_family_id->fetchrow_array();
my @l = split /FAM/, $fix;


my $num = $l[0];
print $num;
$num++;
print $num;

my $filename = 'input.txt';

#Count the rows in the file
my $count = path($filename)->openr_utf8;
my $lines = 0;
while (my $row = <$count>){
    $lines++;
}
close $count;

#Add description to each family
my @famdes = ("samma", "olika");
my $a = @famdes;

if ($lines ne $a){
    die "Error: antalet beskrivningar matchar inte antalet familjer";
}

#Open the file again and insert records into the database
my $th = path($filename)->openr_utf8;
my $int = 0;

while (my $row = <$th>){
    my $var = "FAM$num";
    my $finsert = $famdes[$int];
    $num++;
    $int++;
    $dbh->do('INSERT INTO family(family_stable_id, description) VALUES(?,?)', undef, ($var, $finsert)) or die DBI::errstr;
	
}

=pod    
my @fams = split /,/, $row;
#   print $_, for @fams;
 while (my $ids = shift @fams){
     $dbh->do('INSERT INTO gene_family(gene_id, family_id) VALUES(?)', undef, $ids) or die DBI::errstr;
}   
} 
close $fh;



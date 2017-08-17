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


my $filename = 'input.txt';

#Add you own family descriptions here
my @family_descriptions = ("samma", "olika");  
my $num_fam_desc = @family_descriptions;

#Count the number of rows in the file
my $file = path($filename)->openr_utf8;
my $lines = 0;
while (my $row = <$file>){
    $lines++;
}
close $file;

#Check if there exist a description for each family 
if ($lines ne $num_fam_desc){
    die "Error: The amount of family descriptions does not match the amount of families in the file";
}


#Retrieve the last inserted id so that inserting new family_stable_ids in order are possible
my $last_id = $dbh->prepare('SELECT max(family_id) FROM family');
   $last_id->execute();
my $family_id = $last_id->fetchrow_array();


#Open the file again and insert records into the database
my $read_file = path($filename)->openr_utf8;
my $fam_desc_index = 0;
   $family_id++;


while (my $row = <$read_file>){
    $dbh->do('INSERT INTO family(family_stable_id, description) VALUES(?,?)', undef, ("FAM$family_id", $family_descriptions[$fam_desc_index])) or die DBI::errstr;
    $family_id++;
    $fam_desc_index++;
	    
    my @gene_ids2 = split /,/, $row;
    my @gene_ids = @gene_ids2;
 #   print "@gene_ids\n";
#    my @gene_ids = ("GEN11", "GEN12", "GEN13");
  #  print "@gene_ids2\n";
my $last_insert = $dbh->last_insert_id(undef, 'public', 'family', 'family_id');
    
    while (my $ids = shift @gene_ids){
        my $gid = $dbh->prepare('SELECT gene_id FROM gene WHERE gene_stable_id = ?');
           $gid->bind_param(1, $ids);
	   $gid->execute();
        my $g = $gid->fetchrow_array();
	    
	   $dbh->do('INSERT INTO gene_family(gene_id, family_id) VALUES(?,?)', undef, ($g, $last_insert)) or die DBI::errstr;
	

    
    }

} 




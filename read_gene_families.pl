#!/usr/bin/perl
use strict;
use warnings;
use Path::Tiny;
use DBI;


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


#Add your own family descriptions here
my @family_descriptions = ("They start with the same exon", "They end with the same exon");  
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
    die "Error: The amount of family descriptions does not match the amount of families in the text file";
}


#Retrieve the last inserted id so that family_stable_ids can be inserted in consecutive order
my $last_id = $dbh->prepare('SELECT max(family_id) FROM family');
   $last_id->execute();
my $family_id = $last_id->fetchrow_array();


#Open the file again, read it, and insert records into the database
my $read_file = path($filename)->openr_utf8;
my $fam_desc_index = 0;
   $family_id++;


while (my $row = <$read_file>){
    $dbh->do('INSERT INTO family(family_stable_id, description) VALUES(?,?)', undef, ("FAM$family_id", $family_descriptions[$fam_desc_index])) or die DBI::errstr;
    $fam_desc_index++;
    $family_id++;
    
my @family_gene_ids = split /[,\n]/, $row;
my $last_insert_fam_id = $dbh->last_insert_id(undef, 'public', 'family', 'family_id');
        
    while (my $gene_ids = shift @family_gene_ids){
	my $get_gene_id = $dbh->prepare('SELECT gene_id FROM gene WHERE gene_stable_id = ?');
           $get_gene_id->bind_param(1, $gene_ids);
	   $get_gene_id->execute();
        my $gene_id = $get_gene_id->fetchrow_array();
	    
	   $dbh->do('INSERT INTO gene_family(gene_id, family_id) VALUES(?,?)', undef, ($gene_id, $last_insert_fam_id)) or die DBI::errstr;
	
    }

} 




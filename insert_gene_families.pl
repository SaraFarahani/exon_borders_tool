#!/usr/bin/perl
use strict;
use warnings;
use Path::Tiny;
use DBI;

#USER: write your <database>.db here
my $database = "";

#Connect to SQLite database 
my $driver   = "SQLite";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 }) or die $DBI::errstr;
   $dbh->do('PRAGMA foreign_keys=ON');
print "Opened database successfully\n";


#USER: write your <filename>.txt with gene families here
my $filename = '';

#USER: write your own strings of family stables ids in the array
my @family_stable_ids=("");
my $num_fam_stid=@family_stable_ids;

#USER: write your own strings of with family descriptions in the array 
my @family_descriptions = ("");  
my $num_fam_desc = @family_descriptions;

check_arrays($num_fam_stid, $num_fam_desc);


#Checks that the number of family stable ids and descriptions are correct
sub check_arrays{
my $file = path($filename)->openr_utf8;
my $lines = 0;
while (my $row = <$file>){
    $lines++;
}
close $file;


if ($lines ne $num_fam_desc){
    die "Error: The amount of family descriptions does not match the amount of families in the text file";}
    if($lines ne $num_fam_stid){
	die "Error: The amount of family stable ids does not match the amount of families in the text file";}
}


#Open the file again and reads it 
my $read_file = path($filename)->openr_utf8;
my$row_index=0;
insert_into_database();


#Inserts the records into the database
sub insert_into_database{
    while (my $row = <$read_file>){
	$dbh->do('INSERT INTO family(family_stable_id, description) VALUES(?,?)', undef, ($family_stable_ids[$row_index], $family_descriptions[$row_index])) or die DBI::errstr;
	$row_index++;
    
	my @family_gene_ids = split /[,\n\s+]/, $row;
	my $last_insert_fam_id = $dbh->last_insert_id(undef, 'public', 'family', 'family_id');
        
	while (my $gene_ids = shift @family_gene_ids){
	    my $get_gene_id = $dbh->prepare('SELECT gene_id FROM gene WHERE gene_stable_id = ?');
	       $get_gene_id->bind_param(1, $gene_ids);
	       $get_gene_id->execute();
	    my $gene_id = $get_gene_id->fetchrow_array();
       
	    $dbh->do('INSERT INTO gene_family(gene_id, family_id) VALUES(?,?)', undef, ($gene_id, $last_insert_fam_id)) or die DBI::errstr;	
	}

    } 
}
print time - $^T;

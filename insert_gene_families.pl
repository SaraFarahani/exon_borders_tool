#!/usr/bin/perl
use strict;
use warnings;
use Path::Tiny;
use DBI;

#Command line arguments.
my($database, $filename) = @ARGV;

#Connect to the SQLite database. 
my $driver   = "SQLite";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 }) or die $DBI::errstr;
   $dbh->do('PRAGMA foreign_keys=ON');
print "Opened database successfully\n \n";

#The user is asked to write family stable ids and descriptions in the command line.
print "Write a family stable id for each family in the textfile.\nPress Enter after every id and end with EOF e.g Crtl-D in Linux.\n";
my @family_stable_ids = <STDIN>;
chomp @family_stable_ids;
my $num_fam_stid = @family_stable_ids;

print "\nWrite a family description to every family in the textfile. Press Enter after every description and end with EOF e.g Crtl-D in Linux.\n";
my @family_descriptions = <STDIN>;  
chomp @family_descriptions;
my $num_fam_desc = @family_descriptions;


check_arrays();
#Checks if the number of family stable ids and descriptions are correct.
sub check_arrays{
    my $file = path($filename)->openr_utf8;
    my $lines = 0;
    
    while (my $row = <$file>){
	$lines++;}
    close $file;

    if ($lines ne $num_fam_desc){
	die "Error: The number of family descriptions does not match the amount of families in the text file";}
    if($lines ne $num_fam_stid){
	die "Error: The number of family stable ids does not match the amount of families in the text file";}
}


#Open the file again and read it. 
my $read_file = path($filename)->openr_utf8;
my$row_index=0;
insert_family();

#Inserts data to the family table.
sub insert_family{
    while (my $row = <$read_file>){
	$dbh->do('INSERT INTO family(family_stable_id, description) VALUES(?,?)', undef, ($family_stable_ids[$row_index], $family_descriptions[$row_index])) or die DBI::errstr;
        my $last_insert_fam_id = $dbh->last_insert_id(undef, 'public', 'family', 'family_id');
	insert_gene_family($row, $last_insert_fam_id);
        $row_index++;
    }
}

#Inserts data to the gene_family table.
#Input: a row in the family textfile and a family_id.
sub insert_gene_family{
    my $row = shift;
    my $last_insert_fam_id = shift;
    my @family_gene_ids = split /[,\n\s+]/, $row;
     
    while (my $gene_ids = shift @family_gene_ids){
	my $get_gene_id = $dbh->prepare('SELECT gene_id FROM gene WHERE gene_stable_id = ?');
           $get_gene_id->bind_param(1, $gene_ids);
           $get_gene_id->execute();
        my $gene_id = $get_gene_id->fetchrow_array();

        $dbh->do('INSERT INTO gene_family(gene_id, family_id) VALUES(?,?)', undef, ($gene_id, $last_insert_fam_id)) or die DBI::errstr;
    }
}

#print time - $^T;


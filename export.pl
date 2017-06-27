#!/usr/bin/perl
use warnings;
use strict;
use DBI;
use Path::Tiny;



#Connect to SQLite database
my $driver   = "SQLite";
my $database = "test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 }) or die $DBI::errstr;
   $dbh->do('PRAGMA foreign_keys=ON');
print "Opened database successfully\n";


####### Write file ########
my $dir = path("C:/Users/Sara/home/src");
my $file = $dir->child("file.txt");

my $file_handle = $file->openw_utf8();
#my @list = ('an', 'empty', 'list');

#foreach my $line( @list ){
 #   $file_handle->print($line . "\n");
#}

my @choose_families = ("FAM1");
while (my $family_stable_id = shift @choose_families){
    
    
  ##### Family ###########
    my $get_family_id = $dbh->prepare('SELECT family_id FROM family WHERE family_stable_id = ?');
       $get_family_id->bind_param(1, $family_stable_id);
       $get_family_id->execute();
    my $family_id = $get_family_id->fetchrow_array(); 
 

   ######### Gene ###########
   my $get_gene_id = $dbh->prepare('SELECT gene_id FROM gene_family WHERE family_id = ?');
      $get_gene_id->bind_param(1, $family_id);
      $get_gene_id->execute();
   my $gene_id = $get_gene_id->fetchrow_array();


   my $get_gene_stable_id = $dbh->prepare('SELECT gene_stable_id FROM gene WHERE gene_id = ?');
      $get_gene_stable_id->bind_param(1, $gene_id);
      $get_gene_stable_id->execute();
   my $gene_stable_id = $get_gene_stable_id->fetchrow_array();
    
    
  #### Transcript ###
   my $get_transcript_stable_id = $dbh->prepare('SELECT transcript_stable_id FROM transcript WHERE gene_id= ?');    
      $get_transcript_stable_id->bind_param(1, $gene_id);
      $get_transcript_stable_id->execute();

    while (my $transcript_stable_id =$get_transcript_stable_id->fetchrow_array()){   
$file_handle->print("\n", ">", $family_stable_id, "|", $gene_stable_id, "|", $transcript_stable_id, "|");	
my $get_transcript_seq = $dbh->prepare('SELECT transcript_seq FROM transcript WHERE transcript_stable_id = ?');
	$get_transcript_seq->bind_param(1, $transcript_stable_id);
	$get_transcript_seq->execute();
	my $transcript_seq = $get_transcript_seq->fetchrow_array();
       
     
    my $get_transcript_id = $dbh->prepare('SELECT transcript_id FROM transcript WHERE transcript_stable_id = ?');
       $get_transcript_id->bind_param(1, $transcript_stable_id);
       $get_transcript_id->execute();
my $transcript_id = $get_transcript_id->fetchrow_array();
 

	my $get_exon_id = $dbh->prepare('SELECT exon_id FROM transcript_exon WHERE transcript_id = ?');
	$get_exon_id->bind_param(1, $transcript_id);
        $get_exon_id->execute();
	while (my $exon_id = $get_exon_id->fetchrow_array()){
	#print "e id", $exon_id, "\n";
        my $get_exon_start = $dbh->prepare('SELECT exon_start FROM exon WHERE exon_id = ?');
           $get_exon_start->bind_param(1, $exon_id);
           $get_exon_start->execute();
	my $exon_start = $get_exon_start->fetchrow_array();
	
       
	my $get_exon_end = $dbh->prepare('SELECT exon_end FROM exon WHERE exon_id = ?');
	$get_exon_end->bind_param(1, $exon_id);
	$get_exon_end->execute();
	my $exon_end = $get_exon_end->fetchrow_array();
	
	$file_handle->print($exon_start, ";", $exon_end, ";");
	
	
	}
$file_handle->print("\n", $transcript_seq);

    }
}

  

=pod
#my $dir = ("C:/Users/Sara/home/src");
#my $file = $dir->child("file.txt");
#my $content = $file->slurp_utf8();
#my $file_handle = $file->openr_utf8();
#while ( my $line = $file_handle->getline()){
#print $line;}


my $file = 'file.txt';
open( my $f, '>', $file) or die;
      print $f;
close $f;


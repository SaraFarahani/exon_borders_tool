#!/usr/bin/perl
use warnings;
use strict;
use DBI;
use Bio::EnsEMBL::Registry;



#Connect to SQLite database
my $driver   = "SQLite";
my $database = "test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 }) or die $DBI::errstr;
   $dbh->do('PRAGMA foreign_keys=ON');
print "Opened database successfully\n";



#Connect to the Ensembl database
my $registry = 'Bio::EnsEMBL::Registry';
   $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # alternatively 'useastdb.ensembl.org'
      -user => 'anonymous');



#Retrieve all transcripts for a specific specie
my $transcript_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Transcript' );
my $transclones_ref = $transcript_adaptor->fetch_all('clone');
my @transclones = @{$transclones_ref};
my @translateable_transcripts=();

#The x first transcripts, just for testing. If removed, change to shift @transclones in the while loop.
my @first_transclones = @transclones[0..50];


#Check which transcripts are protein-coding and put them in the list 
while ( my $transcript = shift @first_transclones) {
    my $translateable = $transcript->translateable_seq();
    if ($translateable ne ''){
       push (@translateable_transcripts, $transcript);
    }
}

insert_into_tables(\@translateable_transcripts);


#This subroutine receives a list of protein-coding transcripts and make entries into the database 
sub insert_into_tables{
    my @translateables = @{$_[0]};

    
    #Get and insert specie
    my $first_transcript = $translateables[0];
    my $specie_name = $first_transcript->species();
       $dbh->do('INSERT INTO specie(specie_name) VALUES(?)', undef, $specie_name) or die DBI::errstr;
    my $last_specie_id = $dbh->last_insert_id(undef, 'public', 'specie', 'specie_id');      
    
    
    while (my $data = shift @translateables){

        #Get and insert gene	
	my $gene = $data->get_Gene();
	my $gene_stable_id = $gene->stable_id();
	   $dbh->do('INSERT OR IGNORE INTO gene(specie_id, gene_stable_id) VALUES(?,?)', undef, ($last_specie_id, $gene_stable_id)) or die DBI::errstr;

	#Get and insert protein
        my $protein = $data->translation();
        my $protein_stable_id = $protein->stable_id();
        my $protein_seq = $protein->seq();
           $dbh->do('INSERT INTO protein(protein_stable_id, protein_seq) VALUES(?,?)', undef, ($protein_stable_id, $protein_seq)) or die DBI::errstr;

	#Get and insert the exons forming the transcript
	my $exons_ref=$data->get_all_Exons();
	my @exons_array = @{$exons_ref};
	my @transcript_array= ();

	while(my $exon_ref = shift @exons_array){
	    my $exon_seq = $exon_ref->seq()->seq();
	    push (@transcript_array, $exon_seq)
	}
	my $transcript=join("", @transcript_array);

	my $transcript_stable_id = $data->stable_id();
	my $get_gene_id = $dbh->prepare('SELECT gene_id FROM gene WHERE gene_stable_id = ?');
           $get_gene_id->bind_param(1, $gene_stable_id);
	   $get_gene_id->execute();
	my $transcript_gene_id = $get_gene_id->fetchrow_array();
	my $last_protein = $dbh->last_insert_id(undef, 'public', 'protein', 'protein_id');
           $dbh->do('INSERT INTO transcript(gene_id, protein_id, transcript_stable_id, transcript_seq) VALUES(?,?,?,?)', undef, ($transcript_gene_id, $last_protein, $transcript_stable_id, $transcript)) or die DBI::errstr;

        my $last_transcript_id = $dbh->last_insert_id(undef, 'public', 'transcript', 'transcript_id');       
      	
        
        #Get and insert the first exon for the current transcript and/or insert data into transcript_exon
	my $exons = $data->get_all_Exons(); 	
        my $first_exon = $exons->[0];
	my $first_exon_stable_id = $first_exon->stable_id();	
        my $exon_start = $first_exon->seq_region_start();
        my $exon_end = $first_exon->seq_region_end();
        my $new_start = 1;
        my $new_end = ($exon_end-$exon_start)+1;
           $dbh->do('INSERT INTO exon(exon_stable_id, exon_start, exon_end) VALUES(?,?,?)', undef, ($first_exon_stable_id, $new_start, $new_end)) or die DBI::errstr;
        
	my $last_ex_id =$dbh->last_insert_id(undef, 'public', 'exon', 'exon_id');
	   $dbh->do('INSERT INTO transcript_exon VALUES(?,?)', undef, ($last_transcript_id, $last_ex_id)) or die DBI::errstr;

	
	#Get and insert the remaining exons  
        my @exons = @{$exons};
        my @exon_array = @exons[1 .. $#exons];

	while (my $exon = shift @exon_array){
	    my $exon_stable_id = $exon->stable_id();

	    my $get_previous_exon_id = $dbh->prepare('SELECT max(exon_id) from exon');
               $get_previous_exon_id->execute();
	    my $previous_exon_id = $get_previous_exon_id->fetchrow_array();

	    my $get_previous_exon_end = $dbh->prepare('SELECT exon_end FROM exon WHERE exon_id=?');
	       $get_previous_exon_end->bind_param(1, $previous_exon_id);
	       $get_previous_exon_end->execute();
	    my $previous_exon_end = $get_previous_exon_end->fetchrow_array();
            
	    my $new_exon_start = ($previous_exon_end+1);
	    my $old_exon_start = $exon->seq_region_start();
            my $old_exon_end = $exon->seq_region_end();
            my $new_exon_end = $new_exon_start + ($old_exon_end-$old_exon_start) +1;
               $dbh->do('INSERT INTO exon(exon_stable_id, exon_start, exon_end) VALUES(?,?,?)', undef, ($exon_stable_id, $new_exon_start, $new_exon_end)) or die DBI::errstr;

	    my $last_exon_id =$dbh->last_insert_id(undef, 'public', 'exon', 'exon_id');
               $dbh->do('INSERT INTO transcript_exon VALUES(?,?)', undef, ($last_transcript_id, $last_exon_id)) or die DBI::errstr;	
	}
    }
}

print time - $^T;



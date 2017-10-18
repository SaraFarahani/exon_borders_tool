#!/usr/bin/perl
use warnings;
use strict;
use DBI;
use Bio::EnsEMBL::Registry;


#USER: write your <database>.db here.
my $database = "";

#Connect to SQLite database.
my $driver   = "SQLite";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 }) or die $DBI::errstr;
   $dbh->do('PRAGMA foreign_keys=ON');
print "Opened database successfully\n";

#Connect to the Ensembl database.
my $registry = 'Bio::EnsEMBL::Registry';
   $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # alternatively 'useastdb.ensembl.org'
      -user => 'anonymous');


#USER: choose a specie as the first argument in get_adaptor.
#Retrieve all transcripts for a specific specie.
my $transcript_adaptor = $registry->get_adaptor( '', 'Core', 'Transcript' );
my $transclones_ref = $transcript_adaptor->fetch_all('clone');
my @transclones = @{$transclones_ref};
my @translateable_transcripts=();



#Checks which transcripts that are protein-coding and puts them in the array. 
while ( my $transcript = shift @transclones) {
    my $translateable = $transcript->translateable_seq();
    if ($translateable ne ''){
       push (@translateable_transcripts, $transcript);
    }
}

main(\@translateable_transcripts);


#The main program that handles insertions to tables.
sub main{
    my @translateables = @{$_[0]};
    my $last_specie_id = insert_specie($translateables[0]);
    
    while (my $transcript = shift @translateables){
	my $gene_stable_id = insert_gene($transcript, $last_specie_id);
	my $last_protein_id = insert_protein($transcript);
	my $last_transcript_id = insert_transcript($transcript, $gene_stable_id, $last_protein_id);
	insert_exon($transcript, $last_transcript_id);
    }
}


#Inserts data to the specie table. Needs a transcript reference as input and returns the specie id of the current specie.
sub insert_specie{
    my $transcript = shift;
    my $specie_name = $transcript->species();
    $dbh->do('INSERT INTO specie(specie_name) VALUES(?)', undef, $specie_name) or die DBI::errstr;
    my $last_specie_id = $dbh->last_insert_id(undef, 'public', 'specie', 'specie_id');
    return $last_specie_id;
}

#Inserts data to the gene table. Needs a transcript reference and a specie id as input. Returns the gene stable id of the current gene.
sub insert_gene{
    my $transcript = shift;
    my $last_specie_id = shift;
    my $gene = $transcript->get_Gene();
    my $gene_stable_id = $gene->stable_id();
    $dbh->do('INSERT OR IGNORE INTO gene(specie_id, gene_stable_id) VALUES(?,?)', undef, ($last_specie_id, $gene_stable_id)) or die DBI::errstr;
    return $gene_stable_id;	     
}

#Inserts data to the protein table. Need a transcript reference as input and returns the protein id of the current protein.
sub insert_protein{
    my $transcript = shift;
    my $protein = $transcript->translation();
    my $protein_stable_id = $protein->stable_id();
    my $protein_seq = $protein->seq();
    $dbh->do('INSERT INTO protein(protein_stable_id, protein_seq) VALUES(?,?)', undef, ($protein_stable_id, $protein_seq)) or die DBI::errstr;    
    my $last_protein_id = $dbh->last_insert_id(undef, 'public', 'protein', 'protein_id');
    return $last_protein_id;
}

#Inserts data to the transcript table. Needs a transcript reference, gene stable id and protein id as input. Returns the transcript id of the current transcript.  
sub insert_transcript{
    my $transcript = shift;
    my $gene_stable_id = shift;
    my $last_protein_id = shift;
    my $gene_id = get_gene_id($gene_stable_id);
    my $transcript_stable_id = $transcript->stable_id();
    my $transcript_seq = get_transcript_seq($transcript);

    $dbh->do('INSERT INTO transcript(gene_id, protein_id, transcript_stable_id, transcript_seq) VALUES(?,?,?,?)', undef, ($gene_id, $last_protein_id, $transcript_stable_id, $transcript_seq)) or die DBI::errstr;

    my $last_transcript_id = $dbh->last_insert_id(undef, 'public', 'transcript', 'transcript_id');
    return $last_transcript_id;
}

#Inserts data to the exon table. Needs a transcript reference and a transcript id as input. 
sub insert_exon{
    my $transcript = shift;
    my $last_transcript_id = shift;
    
    my $exons = $transcript->get_all_Exons();
    my $first_exon = $exons->[0];
    my $first_exon_stable_id = $first_exon->stable_id();

    my @first_coordinates = get_first_coordinates($exons->[0]);
    my $new_start = $first_coordinates[0];
    my $new_end = $first_coordinates[1];
    
    $dbh->do('INSERT INTO exon(exon_stable_id, exon_start, exon_end) VALUES(?,?,?)', undef, ($first_exon_stable_id, $new_start, $new_end)) or die DBI::errstr;
    my $last_ex_id =$dbh->last_insert_id(undef, 'public', 'exon', 'exon_id');
    insert_transcript_exon($last_transcript_id, $last_ex_id);

       
        my @exons = @{$exons};
        my @exon_array = @exons[1 .. $#exons];

        while (my $exon = shift @exon_array){
            my $exon_stable_id = $exon->stable_id();
	    my @coordinates = get_coordinates($exon);
	    my $new_exon_start = $coordinates[0];
	    my $new_exon_end = $coordinates[1];
               $dbh->do('INSERT INTO exon(exon_stable_id, exon_start, exon_end) VALUES(?,?,?)', undef, ($exon_stable_id, $new_exon_start, $new_exon_end)) or die DBI::errstr;

            my $last_exon_id =$dbh->last_insert_id(undef, 'public', 'exon', 'exon_id');
	    insert_transcript_exon($last_transcript_id, $last_exon_id);
	 }   
}


#Inserts data to the transcipt_exon table. Needs a transcript id and an exon id as input.
sub insert_transcript_exon{
    my $last_transcript_id = shift;
    my $last_exon_id = shift;
    $dbh->do('INSERT INTO transcript_exon VALUES(?,?)', undef, ($last_transcript_id, $last_exon_id)) or die DBI::errstr;
}

#Retrieves the coordinates for the first exon in every transcript. Needs an exon reference as input and returns the coordinates as an array.
sub get_first_coordinates{
    my $first_exon = shift;
    my $exon_start = $first_exon->seq_region_start();
    my $exon_end = $first_exon->seq_region_end();
    my $new_start = 1;
    my $new_end = ($exon_end-$exon_start)+1;
    my @first_coordinates = ($new_start, $new_end);
    return @first_coordinates;
}

#Retrieves the coordinates for each remaining exon in every transcript. Needs an exon reference as input and returns the coordinates as an array.
sub get_coordinates{
    my $exon = shift;
    my $previous_exon_end = get_last_exon_end();
    my $new_exon_start = ($previous_exon_end+1);
    my $old_exon_start = $exon->seq_region_start();
    my $old_exon_end = $exon->seq_region_end();
    my $new_exon_end = $new_exon_start + ($old_exon_end-$old_exon_start) +1;
    my @coordinates = ($new_exon_start, $new_exon_end);
    return @coordinates;
}

#Returns the last inserted exon end.
sub get_last_exon_end{
    my $get_previous_exon_id = $dbh->prepare('SELECT max(exon_id) from exon');
       $get_previous_exon_id->execute();
    my $previous_exon_id = $get_previous_exon_id->fetchrow_array();

    my $get_previous_exon_end = $dbh->prepare('SELECT exon_end FROM exon WHERE exon_id=?');
       $get_previous_exon_end->bind_param(1, $previous_exon_id);
       $get_previous_exon_end->execute();
    my $previous_exon_end = $get_previous_exon_end->fetchrow_array();
    return $previous_exon_end;
}

#Retrieves the gene id of a specific gene stable id. Needs a gene stable id as input and returns the gene id.
sub get_gene_id{
    my $gene_stable_id = shift;
    my $get_gene_id = $dbh->prepare('SELECT gene_id FROM gene WHERE gene_stable_id = ?');
       $get_gene_id->bind_param(1, $gene_stable_id);
       $get_gene_id->execute();
    my $gene_id = $get_gene_id->fetchrow_array();
    return $gene_id;
}

sub get_transcript_seq{
    my $transcript = shift;
    my $exons_ref=$transcript->get_all_Exons();
    my @exons_array = @{$exons_ref};
    my @transcript_array= ();

    while(my $exon_ref = shift @exons_array){
	my $exon_seq = $exon_ref->seq()->seq();
        push (@transcript_array, $exon_seq)
    }
    my $transcript_seq = join("", @transcript_array);
    return $transcript_seq;
}
    

#print time - $^T;



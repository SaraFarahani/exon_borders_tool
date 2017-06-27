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
#felhantering i databases update?



#Connect to the Ensembl database
#use Bio::EnsEMBL::Registry;
my $registry = 'Bio::EnsEMBL::Registry';
   $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # alternatively 'useastdb.ensembl.org'
      -user => 'anonymous');


#Saccharomyces Cerevisiae
#Retrieve all transcripts from a specific specie
my $transcript_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Transcript' );
my $transclones_ref = $transcript_adaptor->fetch_all('clone');


#Test programme for the five first transcripts
my @transclones = @{$transclones_ref};
my @tenfirst_transclones = @transclones[0..5];
my @translateable_transcripts=();

while ( my $transcript = shift @tenfirst_transclones) {
    my $translateable = $transcript->translateable_seq();
    if ($translateable ne ''){
       push (@translateable_transcripts, $transcript);
    }
}
 

###########Ändra till unique i databasen ?####################
#############join/union etc????????################
insert_into_tables(\@translateable_transcripts);
sub insert_into_tables{
    my @translateables = @{$_[0]};

    ###### Specie #####    
    my $first_transcript = $translateables[0];
    my $specie_name = $first_transcript->species();
       $dbh->do('INSERT INTO specie(specie_name) VALUES(?)', undef, $specie_name) or die DBI::errstr;
    my $last_specie_id = $dbh->last_insert_id(undef, 'public', 'specie', 'specie_id');      

    
    while (my $data = shift @translateables){

        ##### Gene #####	
	my $gene = $data->get_Gene();
	my $gene_id = $gene->stable_id();
	   $dbh->do('INSERT OR IGNORE INTO gene(specie_id, gene_stable_id) VALUES(?,?)', undef, ($last_specie_id, $gene_id)) or die DBI::errstr;

	
	##### Protein #####
        my $protein = $data->translation();
        my $protein_id = $protein->stable_id();
        my $protein_seq = $protein->seq();
           $dbh->do('INSERT INTO protein(protein_stable_id, protein_seq) VALUES(?,?)', undef, ($protein_id, $protein_seq)) or die DBI::errstr;

	
	##### Transcript #####
	my $transcript = $data->seq()->seq();
	my $transcript_id = $data->stable_id();
	my $get_gene_id = $dbh->prepare('SELECT gene_id FROM gene WHERE gene_stable_id = ?');
           $get_gene_id->bind_param(1, $gene_id);
	   $get_gene_id->execute();
	my $t_gene_id = $get_gene_id->fetchrow_array();
	my $last_protein = $dbh->last_insert_id(undef, 'public', 'protein', 'protein_id');
           $dbh->do('INSERT INTO transcript(gene_id, protein_id, transcript_stable_id, transcript_seq) VALUES(?,?,?,?)', undef, ($t_gene_id, $last_protein, $transcript_id, $transcript)) or die DBI::errstr;

        my $last_transcript_id = $dbh->last_insert_id(undef, 'public', 'transcript', 'transcript_id');
        print "transc $last_transcript_id\n";

        ##### Exons #####KOLLA UPP START SLUT JÄMFÖRA MED ENSEMBL! Övertänk med hämta nyckel, foreign key constraint kanske täcker?
	my $exons = $data->get_all_Exons();
	
        my $first_exon = $exons->[0];
	my $first_exon_id = $first_exon->stable_id();
        my $exon_start = $first_exon->seq_region_start();
        my $exon_end = $first_exon->seq_region_end();
        my $new_start = 1;
        my $new_end = ($exon_end-$exon_start);
           $dbh->do('INSERT INTO exon(exon_stable_id, exon_start, exon_end) VALUES(?,?,?)', undef, ($first_exon_id, $new_start, $new_end)) or die DBI::errstr;
        
	
	my $last_exon_id = $dbh->last_insert_id(undef, 'public', 'exon', 'exon_id');
	print "fe $last_exon_id\n";
           $dbh->do('INSERT INTO transcript_exon VALUES(?,?)', undef, ($last_transcript_id, $last_exon_id)) or die DBI::errstr;


        my @exons = @{$exons};
        my @exon_array = @exons[1 .. $#exons];
        while (my $exon = shift @exon_array){
            my $next_exon_id = $exon->stable_id();
            my $last_exon_id = $dbh->last_insert_id(undef, 'public', 'exon', 'exon_id');
            my $last_end = $dbh->prepare('SELECT exon_end FROM exon WHERE exon_id = ?');
               $last_end->bind_param(1, $last_exon_id);
               $last_end->execute();
            my $previous_end = $last_end->fetchrow_array();
            my $next_new_start = ($previous_end+1);
            my $next_old_start = $exon->seq_region_start();
            my $next_old_end = $exon->seq_region_end();
            my $next_new_end = $next_new_start + ($next_old_end-$next_old_start);
               $dbh->do('INSERT INTO exon(exon_stable_id, exon_start, exon_end) VALUES(?,?,?)', undef, ($next_exon_id, $next_new_start, $next_new_end)) or die DBI::errstr;

	    
            #my $get_transcript_id = $dbh->prepare('SELECT transcript_id FROM transcript WHERE transcript_stable_id = ?');
           #$get_transcript_id->bind_param(1, $transcript_id);
           #$get_transcript_id->execute();
	    #my $next_last_transcript_id = $get_transcript_id->fetchrow_array();
            my $next_last_exon_id = $dbh->last_insert_id(undef, 'public', 'exon', 'exon_id');
            print "ne $next_last_exon_id\n";   
            $dbh->do('INSERT INTO transcript_exon VALUES(?,?)', undef, ($last_transcript_id, $next_last_exon_id)) or die DBI::errstr;
        }

       
    }
}

print time - $^T;


=pod
############Test###############
my $f = @translateable_transcripts[0];
my $exons = $f->get_all_Exons();

my $exon = $exons->[0];
my $exonid = $exon->stable_id();
my $eg = $f->get_Gene();
my $egid =$eg->stable_id();
my $t = $f->stable_id();
#print $exon->seq()->seq(), "\n";
my $old_start = $exon->seq_region_start();
my $old_end = $exon->seq_region_end();
my $new_start = 1;
my $new_end = ($old_end-$old_start);
print "$egid\n";
print "$t\n";
print "$exonid\n";
print "Gammal start1: $old_start\n";
print "Gamal slut1: $old_end\n";
print "Ny start1: $new_start\n";
print "Ny slut1: $new_end\n";



my $exon2 = $exons->[1];
my $exonid2 = $exon2->stable_id();

my $old_start2 = $exon2->seq_region_start();
my $old_end2 = $exon2->seq_region_end();
my $new_start2 = ($new_end+1);
my $new_end2 = $new_start2 + ($old_end2-$old_start2);
print "$exonid2\n";
print "Gammal start2: $old_start2\n";
print "Gammal slut2: $old_end2\n";
print "Ny start2: $new_start2\n";
print "Ny slut2: $new_end2\n";

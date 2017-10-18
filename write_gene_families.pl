#!/usr/bin/perl
use warnings;
use strict;
use DBI;
use Path::Tiny;

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


#USER: name the output file <filename>.txt here.
my $output_file=""; 
my $dir=Path::Tiny->cwd;
my $file = $dir->child($output_file);
my $file_handle = $file->openw_utf8();


#USER: write the family stable ids that should be included in the output file. 
my @choose_families = ("");
main();


#Prints the output file
sub main{
    while (my $family_stable_id = shift @choose_families){
	my $family_id = get_family_id($family_stable_id);
	my @gene_ids = get_gene_ids($family_id);

	while (my $gene_id = shift @gene_ids){
	    my $gene_stable_id = get_gene_stable_id($gene_id);
	    my @transcript_stable_ids = get_transcript_stable_id($gene_id);

	    while (my $transcript_stable_id = shift @transcript_stable_ids){
		$file_handle->print(">", $family_stable_id, "|", $gene_stable_id, "|", $transcript_stable_id, "|");
		my $transcript_seq = get_transcript_seq($transcript_stable_id);
		my $transcript_id = get_transcript_id($transcript_stable_id);
		my @exon_ids = get_exon_ids($transcript_id);

		while (my $exon_id = shift @exon_ids){
		    my $exon_start = get_exon_start($exon_id);
		    my $exon_end = get_exon_end($exon_id);
		    $file_handle->print($exon_start, ";", $exon_end, ";");
		}
		$file_handle->print("\n", $transcript_seq, "\n");
	    }
	}
    }
}


#Returns a scalar of the family id, needs a family stable id as input.
sub get_family_id{
    my $family_stable_id = shift;
    my @family_array = ("family_id", "family", "family_stable_id", $family_stable_id, "true");
    return my $family_id = get_data(\@family_array);
}


#Returns an array of gene ids, needs a family id as input.
sub get_gene_ids{
    my $family_id = shift;
    my @gene_array = ("gene_id", "gene_family", "family_id", $family_id, "false");
    return my @gene_ids = get_data(\@gene_array);   
}

#Returns a scalar of the gene stable id, needs a gene id as input.
sub get_gene_stable_id{
    my $gene_id=shift;
    my @gene_array = ("gene_stable_id", "gene", "gene_id", $gene_id, "true");
    return my $gene_stable_id = get_data(\@gene_array);
}

#Returns an array of transcript stable ids, needs a gene id as input.
sub get_transcript_stable_id{
    my $gene_id = shift;
    my @transcript_array = ("transcript_stable_id", "transcript", "gene_id", $gene_id, "false");
    return my @transcript_stable_ids = get_data(\@transcript_array);
}

#Returns a scalar of the transcript sequence, needs a transcript stable id as input.
sub get_transcript_seq{
    my $transcript_stable_id = shift;
    my @transcript_array = ("transcript_seq", "transcript", "transcript_stable_id", $transcript_stable_id, "true");
    return my $transcript_seq = get_data(\@transcript_array);
}

#Returns a scalar of the transcript id, needs a transcript stable id as input.
sub get_transcript_id{
    my $transcript_stable_id = shift;
    my @transcript_array = ("transcript_id", "transcript", "transcript_stable_id", $transcript_stable_id, "true");
    return my $transcript_id = get_data(\@transcript_array);
}

#Returns an array of exon ids, needs a transcript id as input.
sub get_exon_ids{
    my $transcript_id = shift;
    my @exon_array = ("exon_id", "transcript_exon", "transcript_id", $transcript_id, "false");
    return my @exon_ids = get_data(\@exon_array);
}

#Returns a scalar of the exon start, needs an exon id as input.    
sub get_exon_start{
    my $exon_id = shift;
    my @exon_array = ("exon_start", "exon", "exon_id", $exon_id, "true");
    return my $exon_start = get_data(\@exon_array);
}    

#Returns a scalar of the exon end, needs an exon id as input.
sub get_exon_end{
    my $exon_id = shift;
    my @exon_array = ("exon_end", "exon", "exon_id", $exon_id, "true");
    return my $exon_end = get_data(\@exon_array);
}

#Returns the scalar or array results from the database query. 
#Needs an array containing: column name of the seeked value, table name, condition column name, condition column value, boolean ("true" for returning a scalar otherwise it returns an array) 
sub get_data{
    my @array = @{$_[0]};
    my $record=$array[0];
    my $table=$array[1];
    my $column=$array[2];
    my $identifier=$array[3];
    my $boolean=$array[4];

    my $sql=qq{SELECT $record FROM $table WHERE $column = ?};
    my $get_data=$dbh->prepare($sql);
       $get_data->bind_param(1, $identifier);
       $get_data->execute();

    if ($boolean eq "true"){
        my $data = $get_data->fetchrow_array();
        return $data;
    }else{
        my @output_array=();
        while (my $data = $get_data->fetchrow_array()){
            push (@output_array, $data);
        }

    return @output_array;
}   }

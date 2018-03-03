#!/usr/bin/perl
use warnings;
use strict;
use DBI;

#Command line arguments.
my $database = $ARGV[0];
my @choose_families = @ARGV[1..$#ARGV];

#Connect to SQLite database.
my $driver   = "SQLite";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 }) or die $DBI::errstr;
   $dbh->do('PRAGMA foreign_keys=ON');
print "Opened database successfully\n";

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
		print(">", $family_stable_id, "|", $gene_stable_id, "|", $transcript_stable_id, "|");
		my $transcript_seq = get_transcript_seq($transcript_stable_id);
		my $transcript_id = get_transcript_id($transcript_stable_id);
		my @exon_ids = get_exon_ids($transcript_id);

		while (my $exon_id = shift @exon_ids){
		    my $exon_start = get_exon_start($exon_id);
		    my $exon_end = get_exon_end($exon_id);
		    print($exon_start, ";", $exon_end, ";");
		}
		print("\n", $transcript_seq, "\n");
	    }
	}
    }
}


#Input: a family stable id.
#Return: a family id as a scalar.
sub get_family_id{
    my $family_stable_id = shift;
    my @family_array = ("family_id", "family", "family_stable_id", $family_stable_id, "true");
    return my $family_id = get_data(\@family_array);
}

#Input: a family id.
#Return: an array of gene ids.
sub get_gene_ids{
    my $family_id = shift;
    my @gene_array = ("gene_id", "gene_family", "family_id", $family_id, "false");
    return my @gene_ids = get_data(\@gene_array);   
}

#Input: a gene id.
#Return: a gene stable id as a scalar.
sub get_gene_stable_id{
    my $gene_id=shift;
    my @gene_array = ("gene_stable_id", "gene", "gene_id", $gene_id, "true");
    return my $gene_stable_id = get_data(\@gene_array);
}

#Input: a gene id.
#Return: an array of transcript stable ids.
sub get_transcript_stable_id{
    my $gene_id = shift;
    my @transcript_array = ("transcript_stable_id", "transcript", "gene_id", $gene_id, "false");
    return my @transcript_stable_ids = get_data(\@transcript_array);
}

#Input: a transcript stable id.
#Return: a transcript sequence as a scalar.
sub get_transcript_seq{
    my $transcript_stable_id = shift;
    my @transcript_array = ("transcript_seq", "transcript", "transcript_stable_id", $transcript_stable_id, "true");
    return my $transcript_seq = get_data(\@transcript_array);
}

#Input: a transcript stable id.
#Return: a transcript id as a scalar.
sub get_transcript_id{
    my $transcript_stable_id = shift;
    my @transcript_array = ("transcript_id", "transcript", "transcript_stable_id", $transcript_stable_id, "true");
    return my $transcript_id = get_data(\@transcript_array);
}

#Input: a transcript id.
#Return: an array of exon ids.
sub get_exon_ids{
    my $transcript_id = shift;
    my @exon_array = ("exon_id", "transcript_exon", "transcript_id", $transcript_id, "false");
    return my @exon_ids = get_data(\@exon_array);
}

#Input: an exon id.
#Return: an exon start as a scalar.    
sub get_exon_start{
    my $exon_id = shift;
    my @exon_array = ("exon_start", "exon", "exon_id", $exon_id, "true");
    return my $exon_start = get_data(\@exon_array);
}    

#Input: an exon id.
#Return: an exon end as a scalar.
sub get_exon_end{
    my $exon_id = shift;
    my @exon_array = ("exon_end", "exon", "exon_id", $exon_id, "true");
    return my $exon_end = get_data(\@exon_array);
}

#Input: an array containing: column name of the seeked value, table name, condition column name, 
#condition column value, a boolean value ("true" for scalar otherwise array).  
#Return: the results from the database query as a scalar or an array.  
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

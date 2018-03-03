# exon_borders_tool

## Description ##

This is a tool consisting of three different modules, each with an individual functionality:
* import_from_ensembl - imports nucleotide data from the ensembl.org's databases into a local database. The exons' start and end positions are converted from chromosome coordinates to transcript coordinates.
* insert_gene_families - reads a CSV-file containing gene families and inserts data to a database.
* write_gene_families - constructs a FASTA formatted text file of gene families containing nucleotide data including the exons' transcript coordinates.

## Requirements ##
The scripts are written in Perl and interacts with a SQLite3 database.
The import_from_ensembl module is dependent on the Ensembl Perl API, the installation instructions can be found [here](https://www.ensembl.org/info/docs/api/api_installation.html).


##Running the modules with line arguments##
* import_from_ensembl is called with three arguments. The first two are the database name and the species name. For a testrun, the number of transcripts can be limited by assigning the third argument to an integer. Otherwise the third argument should be 'all'. Example1: perl import_from_ensembl.pl exon_borders.db 10. Example2: perl import_from_ensembl.pl exon_borders.db all.

*insert_gene_families is called with the database name and the filename containing the gene families. Example: perl insert_gene_families exon_borders.db newfamilies.txt.

*write_gene_families is called with the database name and an optional number of gene stable ids which should be included in the output file. End the call with an output filename. Example: perl write_gene_families exon_borders.db fam1 fam2 >genefamilies.txt. 
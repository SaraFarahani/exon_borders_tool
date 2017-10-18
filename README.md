# exon_borders_tool

## Description ##

This is a tool consisting of three different modules, each with an individual functionality:
* import_from_ensembl - imports nucleotide data from the ensembl.org's databases into a local database. The exons' start and end positions are converted from chromosome coordinates to transcript coordinates.
* insert_gene_families - reads a CSV-file containing gene families and inserts data to a database.
* write_gene_families - constructs a FASTA formatted text file of gene families containing nucleotide data including the exons' transcript coordinates.

## Requirements ##
The scripts are written in Perl and interacts with a SQLite3 database.
The import_from_ensembl module is dependent on the Ensembl Perl API, the installation instructions can be found [here](https://www.ensembl.org/info/docs/api/api_installation.html).

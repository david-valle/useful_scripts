#!/usr/bin/env perl

use strict;
use Getopt::Long;

##############################
##
## gff3ToBed.pl - This program generates a bed file from a gff3/gtf file.
##
##############################


##############################
# Copyright (c) 2024, David Valle Garcia | david.valle.edu -at- gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
##############################

##############################
## Initializing variables
##############################

my $program_name = "gff3ToBed.pl";
my $version = 1.1;
my $version_date = "Dec 2024";
my $help = 0;
my $infile = undef;
my $outfile = "";
my %record = ();
my $type = 0;
my $column4 = "gene_id";
my $column5 = "gene_name";
#my $add_features = "";
my @add_features = ();
my $missing_value = "NA";
my $gtf = 0;
my $print_version = 0;

##############################
## Read arguments
##############################

if ($#ARGV < 0) {print STDERR "\nNot enough arguments\n"; printhelp(); exit(1);}

GetOptions (
	'help|h'=>\$help,
	'file|f=s'=>\$infile,
	'out|o=s'=>\$outfile,
	'type|t=s'=>\$type,
	'column4|c4=s'=>\$column4,
	'column5|c5=s'=>\$column5,
	'add-features|af=s'=>\@add_features,
	'missing-value|mv=s'=>\$missing_value,
	'gtf'=>\$gtf,
	'version|v'=>\$print_version,
) or die "\nType: '$program_name --help' for details.\n\n";

###############################
## Check arguments and files
##############################

if ($help) {printhelp(); exit(2);} # If selected, print help and exit

if ($print_version) { print "\n$program_name version $version - $version_date\n\n"; exit(2); } # If selected, print program version and exit

if ( !defined($infile)) { # If infile was not provided
	die "\nError: No input Gff3 file was provided. Use -f option.\n\nType: '$program_name --help' for details.\n\n"; 
} elsif (!(-f $infile)) { # Check that infile exists
	die "\nError: Input Gff3 file $infile doesn't exist\n\n"; 
} elsif (-z $infile) { # Check that infile is not empty
	die "\nError: Input Gff3 file $infile is empty\n\n"; 
}

if ($outfile) { # If there is an output file selected
	open (OUT, ">$outfile" ) || die "\nError: Output file $outfile can't be opened. Please check if you have permision to write. Exiting\n\n";
	select(OUT); # Select the output file handler to print
}

###############################
## Open and parse GFF3 file
##############################


open(IN, "$infile") || die "\nError: Gff3 file $infile can't be opened. Exiting\n\n";

while(<IN>){
	next if (/^#/); # Skip if line is a comment
	next if (/^$/); # If the line is empty, skip it
	%record = (); # clean record
	chomp; # Delete the line end
	my @line = split/\t/; # Split the line
	# Save first 6 fields:
	if ($type) {next if ($line[2] ne $type);} # skip if the line is not of the required type
	### Save features to hash ###
	$record{'chr'} = $line[0];
	$record{'source'} = $line[1];
	$record{'type'} = $line[2];
	$record{'start'} = --$line[3]; # Because bed is zero-based, start is decreased
	$record{'end'} = --$line[4]; # Because bed is zero-based, end is decreased
	$record{'score'} = $line[5];
	$record{'strand'} = $line[6];
	$record{'phase'} = $line[7];
	my @attributes = split(/\;/,$line[8]); # Split the attribute column to add keys and values to hash
	foreach my $pair (@attributes){ # For each pair of tag-values
		my @pair_split = ();
		if ($gtf){ # If the file is gtf and not gff3
			$pair =~ /^\s*(.+)\s(.+)$/; # Get key and value with a regular expression that eliminates blank spaces
			@pair_split = ($1,$2); # save in pair array
			$pair_split[1] =~ s/\"//g; # eliminate "" from value
		} else { # If the file is gff3
			@pair_split = split(/\=/,$pair); # split by =
		}
		$record{$pair_split[0]} = $pair_split[1]; # Save to hash
	}
	
	## If column 4 and column 5 are not present in hash, make them equal to missing value
	if (!exists $record{$column4}) { $record{$column4} = $missing_value; }
	if (!exists $record{$column5}) { $record{$column5} = $missing_value; }
	
	## print line
	print "$record{'chr'}\t$record{'start'}\t$record{'end'}\t$record{$column4}\t$record{$column5}\t$record{'strand'}";
	
	## print @added_features
	foreach my $value (@add_features){
	    # If value is not in hash, make it equal to missing value
	    if (!exists $record{$value}) { $record{$value} = $missing_value; }
	    # Print value
		print "\t$record{$value}";
	}
	
	## print final end of line
	print "\n";
}
close(IN);
exit(0);

####################################################
## ### printhelp ###
##
## This function prints the help message.
##
## Receives: Nothing.
## Retrieves: Prints the help	   	
####################################################
sub printhelp {
   print "\n$program_name $version - This program generates a bed file from a gff3/gtf file\n\n";
   print "It generates a bed containing the columns: chr start end gene_id gene_name strand gene_type\n\n";
   print "use:\t$program_name -f [FILE.gff3]  [ Options ]\n\n";
   print "Required argument:\n";
   print "-f | --file\t\tName of your input GFF3 file\n\n";
   print "Optional arguments:\n";
   print "-o | --out\t\tName of your output bed file. If not provided, the result will be printed to STDOUT\n";
   print "-t | --type\t\tOnly print lines matching this feature type (in GFFs 3rd column)\n";
   print "-c4 | --column4\t\tName of the feature you want to print in the 4th column. Default: gene_id\n";
   print "-c5 | --column5\t\tName of the feature you want to print in the 5th column. Default: gene_name\n";
   print "-af | --add-features\tAdd a column with the indicated feature. It can be used multiple times. E.g. '-af gene_type -af transcript_type' will add gene_type and transcript_type to the 7th and 8th columns, respectively. Default: none\n";
   print "-mv | --missing_value\tIf the value from a particular feature is missing, what should be printed. Default: NA\n";
   print "--gtf\t\t\tInput file is in GTF format instead of GFF3 (it expects GFF3 by default)\n";
   print "-h | --help\t\tPrint help\n";
   print "-v | --version\t\tProgram version\n\n";
}

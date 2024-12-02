#!/usr/bin/env perl

use strict;
use Getopt::Long;

##############################
## Substitute_by_id.pl - This programs substitutes the ids in a tabular file for the values from a user-provided dictionary 
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

###############################
## Initializing variables
##############################

my $program_name = "Substitute_by_id.pl";
my $version = "0.3";
my $version_date = "Nov 2024";
my $infile = undef;
my $dict_file = undef;
my $outfile = "";
my $file_id = 1;
my $dict_id = 1;
my $dict_value = 2;
my %dict = ();
my $help = 0;
my $add = 0;
my $ignore = 0;
my $comm = 0;
my $verb = 0;
my $print_version = 0;


##############################
## Reading arguments
##############################

if ($#ARGV < 0) {print STDERR "\nNot enough arguments\n"; printhelp(); exit(1);} # If not enough arguments, print help and exit

GetOptions (
	'help|h'=>\$help,
	'file|f=s'=>\$infile, 
	'dictionary|d=s'=>\$dict_file,
	'file-id|fi=i'=>\$file_id,
	'dictionary-id|di=i'=>\$dict_id,
	'dictionary-value|dv=i'=>\$dict_value,
	'add|a'=>\$add,
	'ignore|i'=>\$ignore,
	'comments|c'=>\$comm,
	'verbose'=>\$verb,
	'outfile|o=s'=>\$outfile,
	'version|v'=>\$print_version,
) or die "\nType: '$program_name --help' for details.\n\n";

# Decrease column numbers to match array 0-based system
$file_id--;
$dict_id--;
$dict_value--;


###############################
## Check arguments and files
##############################

if ($help) { printhelp(); exit(2); } #  If selected, print help and exit

if ($print_version) { print "\n$program_name version $version - $version_date\n\n"; exit(2); } # If selected, print program version and exit

if ( !defined($infile)) { # If infile was not provided
	die "\nError: No input file was provided. Use -f option.\n\nType: '$program_name --help' for details.\n\n"; 
} elsif (!(-f $infile)) { # Check that infile exists
	die "\nError: Input file $infile doesn't exist\n\n"; 
} elsif (-z $infile) { # Check that infile is not empty
	die "\nError: Input file $infile is empty\n\n"; 
}

if ( !defined($dict_file)) { # If dict_file was not provided
	die "\nError: No dictionary file was provided. Use -d option.\n\nType: '$program_name --help' for details.\n\n"; 
} elsif (!(-f $dict_file)) { # Check that dict_file exists
	die "\nError: Dictionary file $dict_file doesn't exist\n\n"; 
} elsif (-z $dict_file) { # Check that dict_file is not empty
	die "\nError: Dictionary file $dict_file is empty\n\n"; 
}

if ($outfile) { # If there is an output file selected
	open (OUT, ">$outfile" ) || die "\nError: Output file $outfile can't be opened. Please check if you have permision to write. Exiting\n\n";
	select(OUT); # Select the output file handler to print
}

###############################
## Open and save dictionary
##############################

# Open dict_file
open (DICT, $dict_file) || die "\nError: dictionary file $dict_file can't be opened\n";

# Save dictionary to hash
while (<DICT>){	
	next if (/^$/); # Skip empty lines
	if ($comm) { next if (/^#/); } # Skip comments if comment flag is on
	chomp;
	my @line = split(/\t/); # split by tab
	if (exists ($dict{$line[$dict_id]}) ) { # If the id was already on record
		if ($verb) { print STDERR "Warning: the id $line[$dict_id] has a duplicated value. Only the first value on record will be used.\n"; } # print warning
	} else { # If it is a new value, add the value to hash
		$dict{$line[$dict_id]} = $line[$dict_value];
	}
}
close(DICT);

# If dict hash is empty, print error and exit
if (!%dict) { 
	print STDERR "\nError: it seems that the dictionary $dict_file is emtpy. Is it a tab file with at least 2 columns? Also check if -di and -dv are existing columns\n\n"; exit (1);
}

###############################
## Scan file and substitute id
##############################

open (FILE, $infile) || die "\nError: file $infile can't be opened\n";

if (!$add){ #if this is a substitution and not and addition

	while (<FILE>){
		next if (/^$/); # Skip empty lines
		if ($comm) { if (/^#/){print "$_"; next;} } # Print the comment and skip the line
		chomp;
		my @line = split(/\t/); # split by tab
		if (exists ($dict{$line[$file_id]}) ) { # If the id is in the dictionary
			for (my $x = 0; $x <= $#line; $x++) { # print all the elements of the line, replacing the id with the value from the dictionary
				if ($x == $file_id) {
					print "$dict{$line[$file_id]}";
				} else {
					print "$line[$x]";
				}
				if ($x < $#line) { print "\t";}else{ print "\n";}
			}
		} elsif (!$ignore) { # If the id is not in the dictionary, print line if ignore flag is off
			print "$_\n";
		}	
	}
} else { # if you are just adding the value to the last column:

	while (<FILE>){
		next if (/^$/); # Skip empty lines
		if ($comm) { if (/^#/){print "$_"; next;} } # Print comment and skip the line
		chomp;
		my @line = split(/\t/);
		if (exists ($dict{$line[$file_id]}) ) { # If the id is in the dictionary
			print "$_\t$dict{$line[$file_id]}\n"; # print the line and the value
		} elsif (!$ignore) { # If not, print line if the ignore flag is off
			print "$_\n";
		}
	}
}

close(FILE);
exit (0);

####################################################
## ### printhelp ###
##
## This function prints the help.
##
## Receives: Nothing.
## Retrieves: Prints the help	   	
####################################################

sub printhelp {
	print "\n$program_name - $version\n\n# This programs takes two tabular lists with a common id, one file and one dictionary. It substitutes the ids on the file with the values on the dictionary\n\n";
	print "use:\t$program_name -f [FILE.tab] -d [DICTIONARY.tab] [ Options ]\n\n";
	print "Required arguments:\n\n";
	print "-f | --file\t\tFile for which you want to make the replacement.\n";
	print "-d | --dictionary\tDictionary file. The dictionary should contain at least two columns: one column with a shared id with the file and another column with the values you want to replace the ids with.\n\n";
	print "Optional arguments:\n";
	print "-o | --out\t\tPrint output to this file (otherwise STDOUT is used)\n";
	print "-fi | --file-id\t\tFile's column that contains the id you want to replace. Column count starts with 1. Default: 1\n";
	print "-di | --dictionary-id\t\tDictionary's column that contains the id. Default: 1\n";
	print "-dv | --dictionary-value\tDictionary's column that contains the value you want to replace the id with. Default: 2\n";
	print "-a | --add\t\tInstead of replacing the id, just add a column at the end with the matching value from the dictionary.\n";
	print "-i | --ignore\t\tFilter out the lines of the file that don't have a match in the dictionary. By default lines with ids not present in the dictionary will be printed unmodified.\n";
	print "-c | --comments\t\tIf a line starts with # (ie, it's a comment), it will be printed as is.\n";
	print "--verbose\t\tPrint warnings of duplicated ids on the dictionary.\n";
	print "-h | --help\t\tPrint this help\n";
	print "-v | --version\t\tProgram version\n\n";
}

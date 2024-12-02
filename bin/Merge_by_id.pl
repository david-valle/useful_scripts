#!/usr/bin/env perl

use strict;
use Getopt::Long;

##############################
## Merge_by_id.pl - This programs takes two tabular lists and merge them based in a shared id
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

my $program_name = "Merge_by_id.pl";
my $version = "0.3";
my $version_date = "Nov 2024";
my $file1 = undef;
my $file2 = undef;
my $outfile = "";
my $col1 = 1;
my $col2 = 1;
my %file = ();
my $help = 0;
my $all = 0;
my $fill = undef;
my $times = 0;
my $keepid = 0;
my $print_version = 0;

##############################
## Reading arguments
##############################

if ($#ARGV < 0) {print STDERR "\nNot enough arguments\n"; printhelp(); exit(1);} # If not enough arguments, print help and exit

#for ( my $x = 0; $x <= $#ARGV; $x++){
#	if ($ARGV [$x] eq "-h" || $ARGV [$x] eq "-help") { $help = 1;  last; }
#	if ($ARGV [$x] eq "-f1" ) { $file1 = $ARGV[++$x]; }
#	if ($ARGV [$x] eq "-f2" ) { $file2 = $ARGV[++$x]; }
#	if ($ARGV [$x] eq "-c1" ) { $col1 = $ARGV[++$x]; $col1--; }
#	if ($ARGV [$x] eq "-c2" ) { $col2 = $ARGV[++$x]; $col2--;}
#	if ($ARGV [$x] eq "-all") {$all = 1;}
#	if ($ARGV [$x] eq "-keepid") {$keepid = 1;}
#	if ($ARGV [$x] eq "-fill") {$fill = $ARGV[++$x];}
#	if ($ARGV [$x] eq "-times") {$times = $ARGV[++$x];}
#}

GetOptions (
	'help|h'=>\$help,
	'file-1|f1=s'=>\$file1, 
	'file-2|f2=s'=>\$file2,
	'column-1|c1=i'=>\$col1,
	'column-2|c2=i'=>\$col2,
	'all|a'=>\$all,
	'keep-id|k'=>\$keepid,
	'fill=s'=>\$fill,
	'times|t=i'=>\$times,
	'outfile|o=s'=>\$outfile,
	'version|v'=>\$print_version,
) or die "\nType: '$program_name --help' for details.\n\n";

# Decrease column numbers to match 0-based array system
$col1--;
$col2--;

###############################
## Check arguments and files
##############################

if ($help) { printhelp(); exit(2); } #  If selected, print help and exit

if ($print_version) { print "\n$program_name version $version - $version_date\n\n"; exit(2); } # If selected, print program version and exit

if ( !defined($file1)) { # If file1 was not provided
	die "\nError: No input file 1 was provided. Use -f1 option.\n\nType: '$program_name --help' for details.\n\n"; 
} elsif (!(-f $file1)) { # Check that file1 exists
	die "\nError: Input file 1 $file1 doesn't exist\n\n"; 
} elsif (-z $file1) { # Check that file1 is not empty
	die "\nError: Input file 1 $file1 is empty\n\n"; 
}

if ( !defined($file2)) { # If file2 was not provided
	die "\nError: No input file 2 was provided. Use -f2 option.\n\nType: '$program_name --help' for details.\n\n"; 
} elsif (!(-f $file2)) { # Check that file1 exists
	die "\nError: Input file 2 $file2 doesn't exist\n\n"; 
} elsif (-z $file2) { # Check that file1 is not empty
	die "\nError: Input file 2 $file2 is empty\n\n"; 
}

if (defined($fill)){ if($times <1) { die "\nError: --times must be defined if you are using --fill option\n"; }}

if ($outfile) { # If there is an output file selected
	open (OUT, ">$outfile" ) || die "\nError: Output file $outfile can't be opened. Please check if you have permision to write. Exiting\n\n";
	select(OUT); # Select the output file handler to print
}

###############################
## Open file 2 and save to hash
##############################

open (FILE, $file2) || die "\nError: file 2 $file2 can't be opened\n";

while (<FILE>){
	next if (/^#/); # Skip comments
	next if (/^$/); # Skip empty lines
	chomp;
	my @line = split(/\t/); # split by tab
	for (my $x = 0; $x <= $#line; $x++) { # add all elements, (except id if indicated)
		if (!$keepid) { next if($x==$col2); }
		$file{$line[$col2]} .= $line[$x];
		if ($x < $#line){
			$file{$line[$col2]} .= "\t"; # Add a tab if this is not the last element
		}
	}
}
close(FILE);

###############################
## Open file1, merge with file2 in hash
##############################

open (FILE, $file1) || die "\nError: file 1 $file1 can't be opened\n";

while (<FILE>){
	next if (/^#/); # Skip comments
	next if (/^$/); # Skip empty lines
	chomp;
	my @line = split(/\t/); # split by tab
	if (exists ($file{$line[$col1]}) ) { # if the id of the column is an id from file2
		print "$_\t"; # print line of file1
		print "$file{$line[$col1]}\n"; # print line of file 2
	} elsif ($all) { # If print all flag is on, print the whole line
		print "$_";
		if (defined($fill)) { # If fill option is used
			for (my $x = 1; $x < $times; $x++) { #print it $times-1 times
				print "\t$fill";
			}
			print "\t$fill\n"; # print the last fill with a return
		} else { 
			print "\n"; # If fill is not used, end the line
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
	print "\n$program_name $version\n\n# This programs takes two tabular lists and merge them based in a shared id.\n\n";
	print "use:\t$program_name -f1 [FILE1.tab] -f2 [FILE2.tab] [ Options ]\n\n";
	print "Required arguments:\n";
	print "-f1 | --file-1\t\tFile 1.\n";
	print "-f2 | --file-2\t\tFile 2. Note that if id's here are duplicated, lines will be attached together and tab separated.\n\n";
	print "Optional arguments:\n";
	print "-c1 | --column-1\tThe id in file1 is on this column. Column count starts with 1. Default: 1.\n";
	print "-c2 | --column-2\tThe id in file2 is on this column. Default: 1.\n";
	print "-o | --out\t\tPrint output to this file (otherwise STDOUT is used)\n";
	print "-a | --all\t\tPrint all lines, even the ones that don't have a match. By default only matching lines are printed\n";
	print "--fill\t\t\tIf a line does not have a match, fill with this character. Requires --all\n";
	print "-t | --times\t\tNumber of times the fill character will be printed. Requires --fill\n";
	print "-k | --keep-id\t\tPrint id column from file 2. By default it discards id column on file 2.\n";
	print "-h | --help\t\tPrint this help\n";
	print "-v | --version\t\tProgram version\n\n";
}
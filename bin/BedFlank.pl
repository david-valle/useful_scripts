#!/usr/bin/env perl

use strict;
use Getopt::Long;

##############################
## BedFlank.pl - This program adds or subtracts from the coordinates of a bed file.
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

my $program_name = "BedFlank.pl";
my $version = "3.0";
my $version_date = "Dec 2024";
my $help = 0;
my $infile = undef;
my $up = 0;
my $down = 0;
my $five_prime = 0; 
my $three_prime = 0; 
my $middle = 0; 
my $no_strand = 0;
my @line = ();
my $silent = 0;
my $genome_file = "";
my %genome_hash = ();
my $mid_coordinate = 0;
my $outfile = "";
my $print_version = 0;

##############################
## Read arguments
##############################

if ($#ARGV < 0) {print STDERR "\nNot enough arguments\n"; printhelp(); exit(1);} # If not enough arguments, print help and exit

GetOptions (
	'help|h'=>\$help,
	'file|f=s'=>\$infile, 
	'upstream|up=i'=>\$up,
	'downstream|down=i'=>\$down,
	'5prime|5'=>\$five_prime,
	'3prime|3'=>\$three_prime,
	'middle-point|mid'=>\$middle,
	'no-strand|ns'=>\$no_strand,
	'silent|s'=>\$silent,
	'genome|g=s'=>\$genome_file,
	'outfile|o=s'=>\$outfile,
	'version|v'=>\$print_version,
) or die "\nType: '$program_name --help' for details.\n\n";

###############################
## Check arguments and files
##############################

if ($help) { printhelp(); exit(2); } #  If selected, print help and exit

if ($print_version) { print "\n$program_name version $version - $version_date\n\n"; exit(2); } # If selected, print program version and exit

if ( !defined($infile)) { # If infile was not provided
	die "\nError: No input bed file was provided. Use -f option.\n\nType: '$program_name --help' for details.\n\n"; 
} elsif (!(-f $infile)) { # Check that infile exists
	die "\nError: Input bed file $infile doesn't exist\n\n"; 
} elsif (-z $infile) { # Check that infile is not empty
	die "\nError: Input bed file $infile is empty\n\n"; 
}

if ($three_prime || $five_prime || $middle) { # If 5 prime, 3 prime or middle point modes are selected
	my $sum = $down + $up;
	if ($sum < 0){ die("\nError: You are trying to subtract more bases than the ones you are adding to a specific point. Disable -5, -3 or -m options or adjust your -up and -down parameters.\n\n"); }
}

if ($three_prime && $five_prime) { # If 5 prime and 3 prime modes are on at the same time
	die("\nError: 5 prime and 3 prime modes are selected at the same time. You can only choose either -5 or -3\n\n");
} elsif ($three_prime && $middle) { # If 3 prime and mid point modes are on at the same time
	die("\nError: 3 prime and mid point modes are selected at the same time. You can only choose either -3 or -mid\n\n");
} elsif ($five_prime && $middle) { # If 5 prime and mid point modes are on at the same time
	die("\nError: 5 prime and mid point modes are selected at the same time. You can only choose either -5 or -mid\n\n");
}

if ($outfile) { # If there is an outfile
	open (OUT, ">$outfile" ) || die "\nError: output file $outfile can't be opened. Please check you have permision to write. Exiting\n\n";
	select(OUT); # Select the output file handler to print
}

##############################
## Saving genome to a hash if genome file was given
##############################

if ($genome_file) {
	unless ( open (GEN, "$genome_file") ) {
		if (!$silent){ print STDERR "\nWarning: .len file $genome_file couldn't be opened. The analysis will continue, but some coordinates may be off the genome size\n\n"; }	
	}
	while (<GEN>){
		chomp;
		next if (/^$/);
		@line = split/\t/;
		$genome_hash{$line[0]} = $line[1]; # Save length with chromosome as hash key 
	}
	close (GEN);
}

##############################
## Open bed file and perform coordinate calculations
##############################

open (BED, "$infile" ) || die("\nError: Bed file $infile can't be opened\n\n"); 

while (<BED>){
	next if (/^$/); # Skip if line is empty
	chomp(); # Delete the line end
	@line = split/\t/; # Split the line
	# Save the start and end coordinates
	my $start = $line[1]; 
	my $end = $line[2];
	if ( ($line[5] =~ /\+/) || $no_strand)  { # If this is a + strand or there's a ignore strand flag
		if ($five_prime) { # If 5' mode is selected
			$end=($start+1); # Change end to start+1 (because bed has open-ended positions)
		} elsif ($three_prime) { # If 3' mode is selected
			$start=($end-1); # Change start to end-1 (because bed is zero based)
		} elsif ($middle) { # If middle point mode is selected
			$mid_coordinate = int(($end-$start)/2); # Calculate half of the size
			$mid_coordinate = $start+$mid_coordinate; # Get the middle coordinate
			$start=$mid_coordinate; # Make start equal than middle
			$end=($mid_coordinate+1); # Make end middle + 1 (because bed is open-ended)
		}
		$start -= $up; # Decrease upstream at start position
		$end += $down; # Increase upstream at end position
	} else { # If this is a negative strand 
		if ($five_prime) { # If 5' mode is selected
			$start=($end-1); # Change start to end-1 (because bed is zero based)
		} elsif ($three_prime) { # If 3' mode is selected
			$end=($start+1); # Change end to start+1 (because bed has open-ended positions)
		} elsif ($middle) { # If middle point mode is selected
			$mid_coordinate = int(($end-$start)/2); # Calculate half of the size
			$mid_coordinate = $start+$mid_coordinate; # Get middle coordinate
			$start=$mid_coordinate; # Make start equal to middle
			$end=($mid_coordinate+1); # Make end middle + 1 (because bed is open-ended)
		}
		$start -= $down; # Decrease downstream at start position
		$end += $up; # Increase upstream at end position
	}
	
	if ($start<0){ $start=0; } # If the start position ends up being less than 0, make it 0

	if ($genome_file) { # If we have a genome file, check that end position is not greater than chr size. If it is, change it
		if (defined $genome_hash{ $line[0] }) { # if the chromosome is recognized and has a valid value
			if ( $end > $genome_hash{ $line[0] } ) { # if the end is greater than the chromosome
				$end = $genome_hash{ $line[0] }; # change it
			}
		} else { # If we don't have a recognized chromosome
			if (!$silent){ # Print warning and give the hash a high value so the warning won't show again
				print STDERR "WARNING: Chromosome: $line[0] is not present in the genome file, ignoring\n"; 
				$genome_hash{ $line[0] } = 99999999999999;
			}
		}
	}

	if ($start >= $end) { # If after the calculation start is bigger than end
		if (!$silent){ # Print warning and skip
			print STDERR "Warning: line: $line[0] $line[1] $line[2] is out of bounds with current settings. Calculated coordinates are:  $line[0] $start $end . Ignoring\n";
		}
		next;
	} else { # If everything looks good, save start and end to line
		$line[1] = $start;
		$line[2] = $end;
	}
	
	# Print the whole line
	for (my $x = 0; $x<$#line; $x++){ print "$line[$x]\t";} print "$line[$#line]\n";
}
close (BED);

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
   print "\n$program_name $version - This program adds or subtracts from the coordinates of a bed file\n\n";
   print "usage:\t$program_name -f [FILE.bed] -up [N] -down [N] [ Options ]\n\n";
   print "Required arguments:\n";
   print "-f | --file\t\tInput bed file - The name of your bed file\n";
   print "-up | --upstream\tAdd or decrease N bases upstream to the bed interval (adds if positive, decreases if negative) DEFAULT: 0\n";
   print "-down | --downstream\tAdd or decrease N bases downstream to the bed interval (adds if positive, decreases if negative) DEFAULT: 0\n\n";
   print "Optional arguments:\n";
   print "-5 | --5prime\t\tAdd or subtract bases only for the 5' coordinate instead of the whole interval (by default adds the upstream to the 5' and the downstream to the 3')\n";
   print "-3 | --3prime\t\tAdd or subtract bases only for the 3' coordinate instead of the whole interval\n";
   print "-mid | --middle-point\tAdd or subtract bases only for middle point between 5' and 3' coordinates instead of the whole interval\n";
   print "-o | --outfile\t\tPrint result to outfile (By default it prints to STDOUT)\n";
   print "-g | --genome\t\tOptional: Genome file. If you want to make sure that all the generated coordinates  will be within the range of the genome, provide a genome file with the size of all chromosomes as follows: <chromName><TAB><chromSize>\n";
   print "-ns | --no-strand\tIgnore strand (default: FALSE)\n";
   print "-s | --silent\t\tSilent mode (do not print warnings)\n";
   print "-h | --help\t\tPrint this help\n";
   print "-v | --version\t\tProgram version\n\n";
}
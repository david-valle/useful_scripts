#!/usr/bin/env perl

use threads;
use strict;
use Getopt::Long;

##############################
## FilterLine.pl This program filters in (or out) the lines (or columns) that match a list of words
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

my $program_name = "FilterLine.pl";
my $version = "3.3";
my $version_date = "Nov 2024";
my $help = 0; # Help flag
my $pb_Exclude = undef; # Include flag
my $pb_Include = undef;# Exclude flag
my $ps_ListFile = undef;
my $ps_InFile = undef;
my $vi_X = 0; # Counter
my @as_List = (); # Array that saves the list
my $ps_Out = ""; # Outfile name
my $pb_CI = 1; # Case insensitive flag. The default is to make case insensitive searches
my $pb_Case = 0; # Case sensitive flag.
my $pb_Exact = 1; # Exact search flag. The default is to make exact searches
my $pb_Fuzzy =0; # Fuzzy search flag 
my $pi_Column = undef; # Column search
my $ps_SplitId = 0; # Split ID char
my $ps_Threads = 1; # Number of threads
my $pb_Verbose = 0; # Verbose flag
my $vi_FilesN = 1; # Number of files for multi-threading
my $print_version = 0; # print version flag

###############################
## Read arguments
##############################

if ($#ARGV < 0) {print STDERR "\nNot enough arguments\n"; printhelp(); exit(1);} # If not enough arguments, print help and exit

GetOptions (
	'help|h'=>\$help,
	'file|f=s'=>\$ps_InFile, 
	'include|i=s'=>\$pb_Include,
	'exclude|e=s'=>\$pb_Exclude,
	'column|c=i'=>\$pi_Column,
	'out|o=s'=>\$ps_Out,
	'threads|p=i'=>\$ps_Threads,
	'split|s=s'=>\$ps_SplitId,
	'fuzzy'=>\$pb_Fuzzy,
	'case|cs'=>\$pb_Case,
	'verbose'=>\$pb_Verbose,
	'version|v'=>\$print_version,
) or die "\nType: '$program_name --help' for details.\n\n";

if(defined($pi_Column)){$pi_Column--;} # Update the column for arrays starting with 0
if ($pb_Case){$pb_CI = 0;}
if ($pb_Fuzzy){$pb_Exact = 0;}
if ($pb_Include){ $ps_ListFile=$pb_Include; } elsif($pb_Exclude){ $ps_ListFile=$pb_Exclude; }

##############################
## Check arguments and files
##############################

if  ($help) { printhelp(); exit(2); } # If selected, print help and exit

if ($print_version) { print "\n$program_name version $version - $version_date\n\n"; exit(2); } # If selected, print program version and exit

if ( !defined($ps_InFile)) { # If file was not provided
	die "Error: No input file was provided. Use -f option.\n\nType: '$program_name --help' for details.\n\n"; 
} 

if ( !defined($ps_ListFile)) { # If there is not include or exclude list
	die "\nError: No include or exclude list was provided. Use -i or -e options.\n\nType: '$program_name --help' for details.\n\n"; 
}

if ($pb_Include && $pb_Exclude) { # If you are trying to include and exclude at the same time
	die "\nError: -i and -e can not be used at the same time.\n\nType: '$program_name --help' for details.\n\n"; 
}

if ($ps_Threads < 1) { 
	die "\nError: Number of threads can not be less than 1\n\nType: '$program_name --help' for details.\n\n"; 
} elsif ($ps_Threads > 1) {
	if (!$ps_Out) {
		die "\nError: When using multiple threads an output file name must be defined. Use -o option.\n\nType: '$program_name --help' for details.\n\n";
	}
}

if ($pi_Column < 0) { 
	die "\nError: Column number can not be less than 1\n\nType: '$program_name --help' for details.\n\n"; 
}

if (!(-f $ps_InFile)) {
	die "\nError: Input file $ps_InFile doesn't exist\n\n"; 
} elsif (-z $ps_InFile) {
	die "\nError: Input file $ps_InFile is empty\n\n"; 
}

if (!(-f $ps_ListFile)) {
	die "\nError: List file $ps_ListFile doesn't exist\n\n"; 
} elsif (-z $ps_ListFile) {
	die "\nError: List file $ps_ListFile is empty\n\n"; 
}

##############################
## Save word list
##############################

open (LIST, "$ps_ListFile" ) || die "\nError: The list file $ps_ListFile can't be opened. Exiting\n\n"; 
$vi_X = 0;
while (<LIST>){
	next if (/^$/); # If the line is empty, skip it
	if(/^(.+)$/){ # If there is something in the line
		chomp(); # delete the return character
		$as_List[$vi_X] = $1; # save in the array
		if ($pb_CI) { $as_List[$vi_X] = lc($as_List[$vi_X]);} # If the comparison is case insensitive, convert everything to lower case
		$vi_X++;
	}
}
close (LIST);

if (!$vi_X) { die "\nError: The list file $ps_ListFile is empty! Exiting\n\n";} # If nothing was saved, exit.

# If the search is exact, sort the array to make the binary search
if ($pb_Exact) { 
	@as_List = sort {$a cmp $b} @as_List; # Sort by string comparison
}

##############################
## MULTIPLE THREADS
##############################

if ($ps_Threads > 1){

######### Split the input file ############

	$vi_X = `wc -l < $ps_InFile`;
	## Get the number of lines each file will contain:
	$vi_X = roundup($vi_X/$ps_Threads);
	## Now use the split function to split the original file into many sub-files, we use the --verbose option and wc -l to get the final number of files generated. Note that the files will be numbered from 11 on
	$vi_FilesN = `split --verbose --lines=$vi_X --numeric-suffixes=11 $ps_InFile ${ps_InFile}_ | wc -l`;

##### OPEN THREADS AND DO THE SEARCH ######

	my @thread_array=(); # The threads are going to be saved on this array
	my @thread_infile=(); # The names of the infiles for each thread are saved in this array
	my $all_infiles = "";
	my @thread_outfile=(); # The names of the outfiles for each thread are saved in this array
	my $all_outfiles = "";
	$vi_X = 11; # This is the counter for the files generated by the split function. Notice that the first file is always 11.
	my $thread_count = 0;

	for ( $thread_count = 0; $thread_count < $vi_FilesN; $thread_count++){
	
	###### Generate the name of in and out files #######
		$thread_infile[$thread_count]= $ps_InFile;
		$thread_infile[$thread_count].="_";
		$thread_infile[$thread_count].=$vi_X;
		$all_infiles .= $thread_infile[$thread_count];
		$all_infiles .= " ";
		
		$thread_outfile[$thread_count]= $ps_Out;
		$thread_outfile[$thread_count].= "_";
		$thread_outfile[$thread_count].= $vi_X;
		$all_outfiles .= $thread_outfile[$thread_count];
		$all_outfiles .= " ";
		
		$vi_X ++;
		
	######### OPEN THREAD WITH FILTERLINE FUNCTION #############
	
		$thread_array[$thread_count] = threads->create('FilterLine', $thread_infile[$thread_count], \@as_List, $pb_Include, $pi_Column, $pb_Exact, $pb_CI, $pb_Verbose, $thread_outfile[$thread_count], $ps_SplitId);
		if (!defined $thread_array[$thread_count]) { print "Warning: thread $thread_count couldn't be started\n\n";}
	}

## Wait until threads are over and monitor status

	for ( $thread_count = 0; $thread_count < $vi_FilesN; $thread_count++){
		$thread_array[$thread_count] -> join();
	}

### Concatenate splited files and delete temp files
	`cat $all_outfiles > $ps_Out`;
	`rm $all_infiles`;
	`rm $all_outfiles`;

} else { 

##############################
## SINGLE THREAD
##############################

	FilterLine($ps_InFile, \@as_List, $pb_Include, $pi_Column, $pb_Exact, $pb_CI, $pb_Verbose, $ps_Out, $ps_SplitId);

}

if ($ps_Out) { print "Finished!\nOutput in $ps_Out\n\n"; }

exit(0);


####################################################
## ### FilterLine ###
##
## This function reads through a file and prints the lines based on whether or not you find matches in an array.
##
## Receives 9 arguments: infile; array_ref; include_flag; column; exact_search_flag; case_flag; verbose_flag; outfile; split_id
## Retrieves: 0 after the search is done. It prints the result to outfile or STDOUT if outfile is empty	   	
####################################################

sub FilterLine {

	my $infile = shift;
	my $array_ref = shift;
	my $include_flag = shift;
	my $column = shift;
	my $exact_search_flag = shift;
	my $case_flag = shift;
	my $verbose_flag = shift;
	my $outfile  = shift;
	my $split_id = shift;

	my $print_flag = 0;
	my $line_string = ""; # Line variable
	my @line_array = (); # Array to save the line (for column search)

###### DEFINE HANDLER FOR OUTPUT #########

	if ($outfile) { # If there is an output file selected
		open (OUT, ">$outfile" ) || die "\nError: The output file $outfile couldn't be opened. Please check you have permision to write. Exiting\n\n";
		if ($verbose_flag) { print STDOUT "\nFiltering $infile\n"; } # Print a message if verbose is selected
		select(OUT); # Select the output file handler to print
	}

##### OPEN AND SCAN THROUGH FILE #######

	open (FILE, "$infile" ) || die "\nError: The input file $infile doesn't exist or can't be opened. Exiting\n\n";

	while (<FILE>){
		if ($include_flag){ # If you want to include
				$print_flag = 0; # Make "not print" as a default
		} else { # Otherwise you want to exclude
			$print_flag = 1; # Make "print" as the default
		}

	##### PREPARE THE LINE #######
		if ($case_flag) { 
			$line_string = lc($_); # Lower case the line if the comparison is case insensitive
		} else { 
			$line_string = $_; 
		}
		chomp ($line_string); # Delete return character
		
		if (defined($column)){ # If the search is column based
			@line_array=split('\t',$line_string); # split the line
			$line_string =$line_array[$column]; # assign the column to the search string
		}
		
	##### EXACT SEARCH #######
		if ($exact_search_flag) { # If the search is exact make a binary search
			my $match_flag = 0;
			if ($split_id) { # If the split id was on, split and make an array with the ids
				my @as_Id_array = split (${split_id},$line_string);	
				foreach my $word (@as_Id_array){ # For each id
					$match_flag = binsearch_str ($word, $array_ref); # Make the binary search
					if ($match_flag) { last; } # If the binary search found something, break the loop			
				}
			} else { # If there's no split id, do the binsearch of the Line
				$match_flag = binsearch_str ($line_string, $array_ref);
			}
				
			if ($match_flag) { # If the line had a match
				if ($include_flag){ # If it's an inclusion list
					$print_flag = 1; # print
				} else { # if it's an exclusion list
					$print_flag = 0; # don't print
				}
			}
	
	##### FUZZY SEARCH #######	
		} else { # If the search is not exact, make a linear fuzzy search
			foreach my $word (@{$array_ref}){ # Search for each word within the list
				my $match_flag = 0;
				if ($line_string=~/$word/) { # Make a fuzzy search and turn on the match flag if there is a hit
					$match_flag = 1;
				}
				if ($match_flag) { # If the line had a match
					if ($include_flag){ # If it's an inclusion list
						$print_flag = 1; # print and exit loop
						last;
					} else { # if it's an exclusion list
						$print_flag = 0; # don't print and exit loop
						last;
					}
				}
			}		
		}

	##### PRINT #######
		if ($print_flag) { # Print to the open handler (STDOUT or $outfile)
				print $_;
		}
	}

##### CLOSE FILE #######
	close (FILE);
	if ($outfile) {
		if ($verbose_flag){print STDOUT "$infile finished\n\n";}
		close(OUT);
	}

##### END WITH ZERO STATUS #######
	return(int(0));
}

####################################################
## ### printhelp ###
##
## This function prints the help.
##
## Receives: Nothing.
## Retrieves: Prints the help	   	
####################################################
sub printhelp {
   print "\n$program_name - $version | This program filters in or out the lines (or columns) from a file that match the words from a list\n\n";
   print "use:\t$program_name  -f [FILE] { -i [LIST] | -e [LIST] } [ Options ]\n\n";
   print "Required arguments:\n";
   print "-f | --file\t\tInput file - File you want to filter.\n";
   print "-i | --include\t\tInclude - File with the list of words you want to INCLUDE (one word per line). Mutually exclusive with -e\n";
   print "-e | --exclude\t\tExclude - File with the list of words you want to EXCLUDE (one word per line). Mutually exclusive with -i\n\n";
   print "Optional arguments:\n";
   print "-o | --out\t\tOutput - Print output to this file (otherwise STDOUT is used). Must be used if multi threading.\n";
   print "-c | --column\t\tColumn search - Search for matches only in this column (from the input file) instead of the whole line. Note that the file must be tab-separated. The column count starts at 1.\n";
   print "-p | --threads\t\tNumber of processors (threads) - Use N processors for the search. More threads will speed up the search, particularly for large files. Requires -o. Default: 1\n";
   print "--case\t\t\tCase sensitive - Make case sensitive comparisons. By default the comparisons are case insensitive.\n";
   print "--fuzzy\t\t\tFuzzy search - By default the program looks for exact matches. With this option you can make a fuzzy search, meaning that if the word you're looking for is contained within another word or phrase it will be counted as a hit. For example, using this mode will include chr10 if you have chr1 on your list. Note that for long lists this mode will be slower than an exact search.\n";
   print "--split\t\t\tSplit the line (or column) of your file by a character - If the line or column has several Id's separated by a character, you can split them and compare them one by one. Use -split char, where char is the character or regular expression you want to split by (uses perl split nomenclature). For example, to split for commas, you use -split ','. This options can be combined with -c to split a single column.\n";
   print "--verbose\t\tPrint details of the run to STDOUT. Requires -o\n";
   print "-h | --help\t\tPrint this help.\n";
   print "-v | --version\t\tProgram version\n\n";
}

####################################################
## ### binsearch_str ###
##
## This function looks for a $needle in a sorted @haystack of strings (uses cmp function to divide the @haystack) using binary search. Returns 1 if the $needle is found, 0 otherwise.
##
## Receives: $needle, \@haystack
## Retrieves: 1 if the needle is found, 0 otherwise	   	
####################################################

sub binsearch_str {
	my $needle = shift; # needle
	my $haystack_ref = shift; # reference to the haystack array
	
	my $min = 0; # Low index to start the search
	my $max = $#{$haystack_ref}; # high index to start the search
		
	if (@{$haystack_ref}){ # If the array is not empty
		my $mid = $min + (int(($max-$min)/2)); # calculate the middle point
		my $comp = $needle cmp $$haystack_ref[$mid]; # Compare $needle to $mid
		if ($comp == 0){ # If cmp is 0 it means that $needle is equal than $mid
			return 1;
		} elsif ($comp == -1) { # If comp is -1 it means than $needle is < than $mid, look in the left side. 
			$max = $mid-1;
		} elsif ($comp == 1) { # If comp is 1 it means than $needle is > $mid, look on the right side of the array.
			$min = $mid+1;
		}
		if ($min>$max) { #If the min index is greater than the max, the array is finished, return 0 
			return 0;
		} else { # otherwise create a sub-array with the new positions and iterate the function
			my @array = @{$haystack_ref}[$min..$max];
			return binsearch_str($needle,\@array);
		}
	} else { # if the array is empty it means that we exhausted the array and the string is not present
		return 0;
	}
}

####################################################
## ### roundup ###
##
## This function rounds up a number.
##
## Receives: a number
## Retrieves: a round up number   	
####################################################

sub roundup {
    my $n = shift;
    return(($n == int($n)) ? $n : int($n + 1))
}

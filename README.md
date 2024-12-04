# Useful scripts
Useful scripts (mainly) for bioinformatics.

---

## Description

These are some scripts that I have written over the years that I find particularly useful. I have used them in several bioinformatic projects.

I hope you find them useful too! 

They run through the terminal in an UNIX based system (Linux, Mac, etc.), so some (very) basic command line knowledge may be required to use them.

If you have questions, problems or suggestions, contact David Valle-Garcia (david dot valle dot edu -at- gmail dot com)

---

## Requirements

### Software
* Perl 5.8+

#### Compatible OS*:
* Ubuntu 24.04.1 LTS
* MacOS 14.6

\* The scripts should run in any UNIX based OS and versions, but testing is required.

---

## Installation

Download scripts from Github repository. Type in a terminal: 
```
git clone https://github.com/david-valle/useful_scripts
```
Go to the folder you just downloaded:
```
cd useful_scripts
```
Give permission to execute the scripts:
```
chmod a+x bin/*
```
Add the folder to your PATH (this will allow you to run the scripts from anywhere in your computer):
```
FOLDER=$(pwd)
```
```
if [ -f ~/.bashrc ]; then
    echo "export PATH=$PATH:$FOLDER/bin" >> ~/.bashrc
elif [ -f ~/.zshrc ]; then
    echo "export PATH=$PATH:$FOLDER/bin" >> ~/.zshrc
fi
```
Then restart your terminal and you will be able to call any of the scripts by name. To test it, type:
```
BedFlank.pl
```
A help message should appear.

---

## Script description

I have 6 useful scripts so far:

* `BedFlank.pl`			Adds or subtracts from the coordinates of a bed file
* `FilterLine.pl`		Filters in or out the lines (or columns) from a file that match the words from a list
* `gff3ToBed.pl`		Generates a bed file from a gff3/gtf file
* `Merge_by_id.pl`		Takes two tabular lists and merge them based in a shared id
* `Substitute_by_id.pl`	Takes two tabular lists with a common id, one file and one dictionary. It substitutes the ids on the file with the values on the dictionary

All scripts have built-in helps that let you know what they do and what options they have. Just type the name of the script followed by -h or --help. For example:
```
BedFlank.pl -h
```

In the (I hope not so distant) future, I will provide here a detailed explanation of each script function.

---

### A few final words

I know that all the things that the scripts do can be done in several ways. With R, python, awk or even excel. However, in my day-to-day work I find them very convenient and easy to use.

They are written in perl for the only reason that that's the language I learned when I learn how to code (yes, you can tell I'm not a spring chicken). I'm sure they can be written in python or R, but I just don't have time to. If you would like to, please be my guest!
#!/usr/bin/perl
# Timur's version of extractor.
# Output is printed to STDOUT. You can aways redirect STDOUT as you wish.
# Works with dumps with multiple DBs and per-DB dumps.
#
# Usage: extractor.pl DB table1 table2 ... 
# Latest version: https://raw.githubusercontent.com/tsolodov/mysqltools/master/extractor.pl

use strict;

my $is_db_mateched = 0;
my $is_table_matched = 0;
my $is_db_closed = 0;
my $s;
my $counter = 0;
my $currtable ="";

# Diable outbut buffering.
$| = 1;

if (!defined($ARGV[0])) {
	print "Usage: extractor.pl DB table1 table2 ... \n";
	exit;
}

my $db = $ARGV[0];
my $currentdb = "";
my %tables=();
for (my $i=1;$i<scalar(@ARGV);$i++) {
  $tables{$ARGV[$i]} = 0;
}
print STDERR "db=$db"; print STDERR " tables: ".join(" ", keys %tables) if (scalar(keys(%tables))>0); print STDERR "\n";


while (defined($s = <STDIN>)) {
	# We need to keep mysqldump's variables to avoid load the dump failure.
	if ($counter < 20) {
		print $s; $counter++; 
		if ($s =~ /Database: (.*)$/) { 
			$currentdb=$+;
			print STDERR $currentdb."\n";
			if ($currentdb eq $db) { $is_db_mateched = 1; } }
	}
	
	if ($s =~ /^USE `([^`]+)`;/) {
	$currentdb = $1;
    print STDERR $currentdb."\n";
    if ($is_db_mateched) { print STDERR "Closing pipe due another DB found.\n"; exit 0; }
    if ($currentdb eq $db) { $is_db_mateched = 1; }
    #don't need USE <DB> in the result.
    next;
    }

	if ($is_db_mateched) {
		if (scalar(keys((%tables)) == 0)) {
			print $s;
		}
		else {
			if ($s =~ /^DROP TABLE IF EXISTS `([^`]+)`;/) { 
				$is_table_matched=0;
				my $all_tables_matched_marker = 1;
				foreach my $k (keys %tables) { if ($tables{$k} == 0) { $all_tables_matched_marker=0;} }
				if ($all_tables_matched_marker == 1) { print STDERR "All tables were restored. Exiting...\n"; exit 0; }
				$currtable = $1; 
				print STDERR "    table: $currtable\n";
				foreach my $k (keys %tables) { if ( $k eq $currtable ) { $is_table_matched=1; $tables{$k} = 1; }} 
			}
			#Workaround for last table in DB
			if (($s =~ /Final view structure for view/) || ($s =~ /DROP PROCEDURE IF EXISTS/)) {exit 0;}
			if ($is_table_matched) {print $s;}
		}
	      
    
	}
}

if ($is_db_mateched == 0) { print STDERR "DB not found\n"; exit 1;}

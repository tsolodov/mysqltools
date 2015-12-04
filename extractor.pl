#!/usr/bin/perl
# Timur's version of extractor.
# Output is printed to STDOUT. You can aways redirect STDOUT as you wish.
# Works with dumps with multiple DBs and per-DB dumps.
#
# Usage: extractor.pl DB table1 table2 ... 

use strict;

my $is_db_mateched = 0;
my $is_table_matched = 0;
my $is_db_closed = 0;
my $s;
my $counter = 0;
my $currtable ="";

if (!defined($ARGV[0])) {
	print "Usage: extractor.pl DB table1 table2 ... \n";
	exit;
}

my $db = $ARGV[0];
my $currentdb = "";
my @tables;
for (my $i=1;$i<scalar(@ARGV);$i++) {
  push(@tables, $ARGV[$i]);
}
print STDERR "db=$db, tables: ".join(" ", @tables)."\n" if (scalar(@tables)>0);



while (defined($s = <STDIN>)) {
	# We need to keep mysqldump's variables to avoid load the dump failure.
	if ($counter < 20) {
		print $s; $counter++; 
		if ($s =~ /Database: (.*)$/) { 
			$currentdb=$+;
			#print ":$currentdb:$db:\n"; 
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
		if (scalar(@tables) == 0) {
			print $s;
		}
		else {
			if ($s =~ /^DROP TABLE IF EXISTS `([^`]+)`;/) { 
				$is_table_matched=0; 
				$currtable = $1; 
				print STDERR "    table: $currtable\n";
				foreach my $k (@tables) { if ( $k eq $currtable ) { $is_table_matched=1; }} 
			}
			#Workaround for last table in DB
			if (($s =~ /Final view structure for view/) || ($s =~ /DROP PROCEDURE IF EXISTS/)) {exit 0;}
			if ($is_table_matched) {print $s;}
		}
	      
    
	}
}

if ($is_db_mateched == 0) { print STDERR "DB not found\n"; exit 1;}
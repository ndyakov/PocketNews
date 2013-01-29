#!/usr/bin/perl
use strict;
use warnings;
require PocketNews::DB;
package main;
$\ = "\n";
my $db = PocketNews::DB->new( _filename => "test.sqlite");
print "LAST ID : " . $db->getLastId("news");
print "ADD NEW : " . $db->addNew("test");
print "GET LAST ID AFTER ADDING : " . $db->getLastId("news");
print "CHECK IF EXISTS : " . $db->exists("test");
print "RESTORE ID RESULT : " . $db->restoreAI("news");
print "GET LAST ID AFTER RESTORING : " . $db->getLastId("news");

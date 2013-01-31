#!/usr/bin/perl
use strict;
use warnings;
require PocketNews::Config;
require PocketNews::DB;
require PocketNews::NewsFetcher;
use Data::Dumper;
$\ = "\n";

MAIN: 
{
    my $cfg = PocketNews::Config->new( _args => \@ARGV );;
    my $db = PocketNews::DB->new( _filename => $cfg->get("dbfile"));
    my $nf = PocketNews::NewsFetcher->new( _feeds => $cfg->get("rss"), _tags => $cfg->get("tags"));
    print $nf->getNewspaper($cfg,$db);
}


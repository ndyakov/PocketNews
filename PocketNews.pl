#!/usr/bin/perl
use strict;
use warnings;
require PocketNews::DB;
require PocketNews::NewsFetcher;
require XML::Simple;
use Data::Dumper;
$\ = "\n";

sub ReadConfig{
    my $cfgfile = shift;
    my $xml = new XML::Simple;
    my $cfg = $xml->XMLin($cfgfile, KeyAttr => { block => 'type' }, ValueAttr => ['value'], ForceArray => [ 'block', 'item', 'link']);
    return $cfg if CheckConfig($cfg) or die("ERROR IN CONF FILE : $cfgfile");
}

sub CheckConfig{
    my $cfg = shift;
    my $rss = $cfg->{block}->{rss}->{link} if defined $cfg->{block}->{rss}->{link};
    my $tags = $cfg->{block}->{tags}->{tag} if defined $cfg->{block}->{tags}->{tag};
    return 1 if (ref($cfg) eq 'HASH' && exists $cfg->{block}->{system} && exists $cfg->{block}->{system}->{DBFILE} 
    && ( $cfg->{block}->{system}->{WEATHER} eq 0 || ( $cfg->{block}->{system}->{WEATHER} eq 1 && $cfg->{block}->{system}->{LOCATION} ) ) && $#$tags >= 0 && $#$rss >= 0);
}
MAIN: 
{
    my $cfgfile;
    if($#ARGV >= 0){ 
        $cfgfile = $ARGV[0];
    }else{ 
        $cfgfile = "default.conf";
    }
    my $cfg = ReadConfig($cfgfile);
    my $db = PocketNews::DB->new( _filename => $cfg->{block}->{system}->{DBFILE});
    my $nf = PocketNews::NewsFetcher->new( _feeds => $cfg->{block}->{rss}->{link}, _tags => $cfg->{block}->{tags}->{tag});
    my $news = $nf->catchThemAll($db);
    print Dumper($news);
}


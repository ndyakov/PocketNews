#!/usr/bin/perl
use strict;
use warnings;
require PocketNews::DB;
require XML::Simple;
use Data::Dumper;
$\ = "\n";

sub ReadConfig{
    my $cfgfile = shift;
    my $xml = new XML::Simple;
    my $cfg = $xml->XMLin($cfgfile, KeyAttr => { block => 'type', item => 'name' }, ForceArray => [ 'block', 'item' ]);
    return $cfg if CheckConfig($cfg) or die("ERROR IN CONF FILE : $cfgfile");
}

sub CheckConfig{
    my $cfg = shift;
    my $rss = $cfg->{block}->{rss}->{item} if defined $cfg->{block}->{rss}->{item};
    my $tags = $cfg->{block}->{tag}->{item} if defined $cfg->{block}->{tag}->{item};
    return 1 if (ref($cfg) eq 'HASH' && exists $cfg->{block}->{system} && exists $cfg->{block}->{system}->{item}->{DBFILE} 
    && ( $cfg->{block}->{system}->{item}->{WEATHER}->{content} eq 0 || ( $cfg->{block}->{system}->{item}->{WEATHER}->{content} eq 1 && $cfg->{block}->{system}->{item}->{LOCATION} ) ) && $#$tags >= 0 && $#$rss >= 0);
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
    my $db = PocketNews::DB->new( _filename => $cfg->{block}->{system}->{item}->{DBFILE}->{content});
}


package PocketNews::NewsFetcher;
=pod
=head1 NAME
PocketNews::NewsFetcher
=head1 SYNOPSIS
    my $nf = PocketNews::NewsFetcher->new(_feeds => [feed1,feed2,feed3], _tags => [tag1,tag2,tag3]);
=head1 DESCRIPTION
NewsFetcher that gets rss feeds.
=head1 METHODS

=cut

use strict;
use warnings;
use XML::RSS::Parser;
use LWP::Simple;
use Data::Dumper;
our $VERSION = '0.01';
=pod
=head2 new
  my $nf = PocketNews::NewsFetcher(_feeds => [feed1,feed2,feed3], _tags => [tag1,tag2,tag3]);
=cut

sub new {
    my $class = shift;
    my $self  = bless { @_ }, $class;
    return $self;
}

my %news;
sub catchThemAll{
    my $self = shift;
    my $db = shift;
    my $links = $self->{_feeds};
    my $tags = $self->{_tags};
    $tags = join('|',@$tags);
    my $xml;
    my $parser = XML::RSS::Parser->new();
    for my $link (@$links)
    {
        my %feed_news;
        $xml = get($link);
        my $feed = $parser->parse_string($xml) or next;
        my $feed_title = $feed->query('/channel/title')->text_content;
        for my $item  ( $feed->query('//item') )
        {
            my $title = $item->query('title')->text_content;
            if($title =~ m/$tags/i && !$db->exists($title))
            {
                my $description = $item->query('description')->text_content;
                $description =~ s|<img .*? />| |i;
                $feed_news{$title}=$description;
                $db->addNew($title);
            }
            else
            {
                next;
            }
        }
        $news{$feed_title}=\%feed_news;
    }
    return \%news;
}

1;
=pod
=head1 AUTHOR
ndyakov
=cut

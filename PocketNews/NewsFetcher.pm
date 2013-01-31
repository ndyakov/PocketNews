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
use Cwd;
use File::Util qw( SL );
use HTML::Template;
use Data::Dumper;
use Time::Piece;
use EBook::EPUB;
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
sub _getRSSFeeds{
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
                $description =~ s|<img.*?/>| |ig;
                $description =~ s|<img.*?>| |ig; # не си затварят таговете както трябва ... тцтц
                $description =~ s|style=".*?"| |ig;
                $description =~ s|<iframe.*?</iframe>| |ig;
                $feed_news{$title}=$description;
                #$db->addNew($title);
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

sub getNewspaper{
    my ($self,$cfg,$db) = @_;
    $self->_getRSSFeeds($db);
    my $page_counter = 0;
    my $cover_template = $cfg->get('template_path').SL.'cover.tmpl';
    my $page_template = $cfg->get('template_path').SL.'page.tmpl';
    my $stylesheet = $cfg->get('template_path').SL.'style.css';
    my $cover = HTML::Template->new(filename => 'cover.tmpl', path => $cfg->get('template_path'), utf8 => 1,);
    
    my $cover_html_file = $cfg->get('temp_path').SL.'cover.html';
    my $page_html_file =  $cfg->get('temp_path').SL.'page';
    
    open COVER, '>'.$cover_html_file or warn ( "ERROR in opening COVER.html" );
    $cover->param(COVER_TITLE => $cfg->get('title'));
    $cover->param(WEATHER => $cfg->get('weather') );
    $cover->param(COVER_DATE => localtime->strftime('%Y-%m-%d %H:%M') );
    #need weather app to be ready!
    $cover->output(print_to => *COVER);
    close COVER;
    for my $source ( sort keys %news )
    {
        $page_counter++;
        open PAGE, '>'.$page_html_file.$page_counter.'.html' or warn ( "ERROR in opening $page_html_file.$page_counter.html" ); 
        my $page = HTML::Template->new(filename => 'page.tmpl' , path => $cfg->get('template_path') , utf8 => 1,);
        $page->param(
            PAGE_TITLE => "News Page #$page_counter",
            PAGE_SOURCE => $source,
            ARTICLE_LOOP => $self->_prepareArticles($news{$source}),
            );
        $page->output(print_to => *PAGE);
        close PAGE;
    }
    return $self->_generateEPUB($cfg);
}

sub _generateEPUB{
    my($self, $cfg) = @_;
    my $epub = EBook::EPUB->new;
    my $epub_path = $cfg->get('epub_path');
    my $today = localtime->strftime('%Y-%m-%d');
    $epub->add_title($cfg->get('title').$today);
    $epub->add_author('PocketNews');
    $epub->add_language($cfg->get('language'));
    $epub->copy_stylesheet($cfg->get('template_path').SL.'style.css', 'style.css');
    opendir (TMPDIR, $cfg->get('temp_path'));
    my @files = readdir TMPDIR;
    foreach my $file (@files)
    {   if ($file =~ m|.html$|i) 
        {
            $epub->copy_xhtml($cfg->get('temp_path').SL.$file,$file);
           # unlink $cfg->get('temp_path').SL.$file;
        }
    }
    if($epub->pack_zip($epub_path.SL.'Newspaper-'.$today.'.epub'))
    {
        return $epub_path.SL.'Newspaper-'.$today.'.epub';
    }
    else
    {
     $epub->pack_zip($cfg->get('temp_path').SL.'Newspaper-'.$today.'.epub');
     return $cfg->get('temp_path').SL.'Newspaper-'.$today.'.epub';
    }
}

sub _prepareArticles{
    my $self = shift;
    my $articles = shift;
    my @result;
    while ( my ($title,$content) = each %$articles)
    {
        my %temp;
        $temp{ARTICLE_TITLE} = $title;
        $temp{ARTICLE_CONTENT} = $content;
        push @result,\%temp;
    }
    return \@result;
}

=pod
=head1 AUTHOR
ndyakov
=cut

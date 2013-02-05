package PocketNews::NewsFetcher;
=pod
=head1 NAME
PocketNews::NewsFetcher
=head1 SYNOPSIS
$cfg should be PocketNews::Config instance.
$db should be PocketNews::DB instance.
    use PocketNews::NewsFetcher;
    use PocketNews::DB;
    use PocketNews::Config;
    ...
    my $nf = PocketNews::NewsFetcher->new(_feeds => [feed1,feed2,feed3], _tags => [tag1,tag2,tag3]);
    my $location = $nf->getNewspaper($cfg,$db);
    print "\n Your newspaper is located at : ".$location."\n";
=head1 DESCRIPTION
NewsFetcher that gets rss feeds.
=head1 METHODS

=cut

use strict;
use XML::RSS::Parser;
use LWP::Simple;
use Cwd;
use File::Util qw( SL );
use HTML::Template;
use Time::Piece;
use EBook::EPUB;
use PocketNews::Weather;
use WWW::BashOrg;
our $VERSION = '0.07';
my %news;
=pod
=head2 new
  my $nf = PocketNews::NewsFetcher(_feeds => [feed1,feed2,feed3], _tags => [tag1,tag2,tag3]);
=cut
sub new {
    my $class = shift;
    print "\n Executing $class v$VERSION." if (defined $::v or defined $::verbose);
    my $self  = bless { @_ }, $class;
    return $self;
}


=pod
=head2 getNewspaper
Loads template files and fills them with information 
with the help of other methods in the class. Calls 
$self->_generateEPUB($cfg) at the end.
  my $location = $nf->getNewspaper($cfg,$db);
Returns scalar with the full path of generated EPUB.
=cut
sub getNewspaper{
    my ($self,$cfg,$db) = @_;
    $self->_getRSSFeeds($db);
    my $page_counter = 0;
    print "\n\n Preparing HTML from template ".$cfg->get('template')."." if (defined $::v or defined $::verbose);
    my $cover_template = $cfg->get('template_path').SL.'cover.tmpl';
    my $page_template = $cfg->get('template_path').SL.'page.tmpl';
    my $stylesheet = $cfg->get('template_path').SL.'style.css';
    my $cover = HTML::Template->new(filename => 'cover.tmpl', path => $cfg->get('template_path'), utf8 => 1,);
    print "\n\n Preparing cover page.\n" if (defined $::v or defined $::verbose);
    my $cover_html_file = $cfg->get('temp_path').SL.'cover.html';
    my $page_html_file =  $cfg->get('temp_path').SL.'page';
    
    # START Building Cover Page START
    open COVER, '>'.$cover_html_file or warn ( "ERROR in opening COVER.html" ); 
    $cover->param(COVER_TITLE => $cfg->get('title'),
                  WEATHER => $cfg->get('weather'),
                  BASHORG => $cfg->get('bashorg'), 
                  COVER_DATE => localtime->strftime('%Y-%m-%d %H:%M'));
    if($cfg->get('bashorg'))
    {
         print "\n Adding bash.org quote..." if (defined $::v or defined $::verbose);
         my $bashorg = WWW::BashOrg->new;
         $cover->param(QUOTE => $bashorg->random);
         print "done." if (defined $::v or defined $::verbose);
    }
    if($cfg->get('weather'))
    {
        print "\n Adding weather forecast for ".$cfg->get('location')."..." if (defined $::v or defined $::verbose);
        my $weather = PocketNews::Weather->new(_location => $cfg->get('location'));
        $cover->param(WEATHER_LOCATION => $cfg->get('location'),
                      WEATHER_LOOP => $weather->getWeather());
        print "done." if (defined $::v or defined $::verbose);
    }
    $cover->output(print_to => *COVER);
    close COVER;
    # END Building Cover Page  END
    print "\n" if (defined $::v or defined $::verbose);
    
    # START Building Inner Pages START
    for my $source ( sort keys %news )
    {
        $page_counter++;
        print "\n Preparing page#$page_counter ( $source )..." if (defined $::v or defined $::verbose);
        open PAGE, '>'.$page_html_file.$page_counter.'.html' or warn ( "ERROR in opening $page_html_file.$page_counter.html" ); 
        my $page = HTML::Template->new(filename => 'page.tmpl' , path => $cfg->get('template_path') , utf8 => 1,);
        $page->param(
            PAGE_TITLE => "News Page #$page_counter",
            PAGE_SOURCE => $source,
            ARTICLE_LOOP => $self->_prepareArticles($news{$source}),
            );
        $page->output(print_to => *PAGE);
        close PAGE;
        print "done." if (defined $::v or defined $::verbose);
    }
    # END Building Inner Pages END
    return $self->_generateEPUB($cfg);
}
1;

=pod
=head2 _getRSSFeeds
PRIVATE - Should be use only by this class methods.
Gets the articles from the feeds, adding only those
who match some tag and wasn't added before (checks the DB)
in a hash. 
  $self->_getRSSFeeds($db);
Returns reference to hash whit needed news articles.
=cut
sub _getRSSFeeds{
    my $self = shift;
    my $db = shift;
    print "\n\n Getting RSS Feeds started." if (defined $::v or defined $::verbose);
    my $links = $self->{_feeds};
    my $tags = $self->{_tags};
    $tags = join('|',@$tags);
    my $xml;
    my $parser = XML::RSS::Parser->new();
    for my $link (@$links)
    {
        my $article_counter = 0;
        my %feed_news;
        print "\n\n------------\n Getting RSS Feeds from $link.\n------------\n" if (defined $::v or defined $::verbose);
        $xml = get($link);
        my $feed = $parser->parse_string($xml) or next;
        my $feed_title = $feed->query('/channel/title')->text_content;
        for my $item  ( $feed->query('//item') )
        {
            my $title = $item->query('title')->text_content;
            print "\n Article -- $title " if (defined $::v or defined $::verbose);
            if($title =~ m/\b($tags)\b/i && !$db->exists($title))
            {
                print "match tag $1, ADDING!" if (defined $::v or defined $::verbose);
                my $description = "<p>Tagged for <span class=\"tag\" >$1</span></p>".$item->query('description')->text_content;
                $description =~ s|<img.*?/>| |ig;
                $description =~ s|<img.*?>| |ig; # не си затварят таговете както трябва ... тцтц
                $description =~ s|style=".*?"| |ig;
                $description =~ s|<iframe.*?</iframe>| |ig;
                $feed_news{$title}=$description;
                $article_counter++;
                $db->addNew($title);
            }
            else
            {
                print " -- doesn't match any tag or already added before, SKIPPING!" if (defined $::v or defined $::verbose);
                next;
            }
        }
        $news{$feed_title}=\%feed_news if $article_counter > 0;
        print "\n--\n $article_counter article(s) added from $feed_title. \n--\n" if ((defined $::v or defined $::verbose) and $article_counter > 0 );
        print "\n--\n None articles added from $feed_title. \n--\n" if ((defined $::v or defined $::verbose) and $article_counter == 0 );
    }
    return \%news;
}
1;


=head2 _generateEPUB
PRIVATE - Should be use only by this class methods.
Looks in temp_path and builds EPUB from current html files
in it. Removing them afterwards. Adds the stylesheet from
the chosen template. Saves the generated EPUB in the provided 
path or in temp_path if provided is not writable.
  $location = $self->_generateEPUB($cfg);
Returns scalar with the full path of generated EPUB.
=cut
sub _generateEPUB{
    my($self, $cfg) = @_;
    print "\n\n Generating EPUB.\n" if (defined $::v or defined $::verbose);
    my $epub = EBook::EPUB->new;
    my $epub_path = $cfg->get('epub_path');
    $epub_path = $::O if defined $::O;
    my $today = localtime->strftime('%Y-%m-%d');
    $epub->add_title('PN-'.$today.$cfg->get('title'));
    $epub->add_author('PocketNews');
    $epub->add_language($cfg->get('language'));
    $epub->copy_stylesheet($cfg->get('template_path').SL.'style.css', 'style.css');
    opendir (TMPDIR, $cfg->get('temp_path'));
    my @files = readdir TMPDIR;
    foreach my $file (@files)
    {   
        
        if ($file =~ m|.html$|i) 
        {
            print "\n Adding $file to EPUB and deleting it..." if (defined $::v or defined $::verbose); 
            $epub->copy_xhtml($cfg->get('temp_path').SL.$file,$file);
            unlink $cfg->get('temp_path').SL.$file;
            print "done." if (defined $::v or defined $::verbose);
        }
    }
    if( open(TEST, '>'.$epub_path.SL.'Newspaper-'.$today.'.epub' ))
    {
        close TEST;
        print "\n\n Saving EPUB in $epub_path..." if (defined $::v or defined $::verbose);
        $epub->pack_zip($epub_path.SL.'Newspaper-'.$today.'.epub');
        print "done." if (defined $::v or defined $::verbose);
        return $epub_path.SL.'Newspaper-'.$today.'.epub';
    }
    else
    {
         print "\n\n Saving EPUB in ".$cfg->get('temp_path')."..." if (defined $::v or defined $::verbose);
         $epub->pack_zip($cfg->get('temp_path').SL.'Newspaper-'.$today.'.epub');
         print "done." if (defined $::v or defined $::verbose);
         return $cfg->get('temp_path').SL.'Newspaper-'.$today.'.epub';
    }
}


=head2 _prepareArticles
PRIVATE - Should be use only by this class methods.
Prepares the already fetched articles ( from one source ) for the TMPL_LOOP.
   ...ARTICLE_LOOP => $self->_prepareArticles($news{$source}),...
Returns reference to an array of hash references.
=cut
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

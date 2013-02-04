#!/usr/bin/perl -s 
use strict;
use PocketNews::Config;
use PocketNews::DB;
use PocketNews::NewsFetcher;
our $VERSION = '0.15';
MAIN: 
{
    print "\n Executing PocketNews v$VERSION..." if (defined $::v or defined $::verbose);
    printUsage() and exit(0) if ( defined $::h or defined $::help );
    printVersion() and exit(0) if defined $::version;
    my $cfg = PocketNews::Config->new;
    my $db = PocketNews::DB->new( _filename => $cfg->get("dbfile"));
    my $nf = PocketNews::NewsFetcher->new( _feeds => $cfg->get("rss"), _tags => $cfg->get("tags"));
    my $location = $nf->getNewspaper($cfg,$db);
    print "\n Your Newspaper is located at : $location \n";
}
sub printUsage
{
    print <<USAGEMSG
Usage: perl PocketNews.pl [OPTION] [-c=CONFIG_FILE] [-O=OUTPUT_PATH]
      Option                        Meaning
    -h -help                    Help. Prints a summary of the options.
    -v -verbose                 Verbose. Prints usefull information while running.
    -version                    Prints the version of this copy.
    -c=CONFIG_FILE              Using custom configuration file.
                                By default will use default.conf.
    -O=OUTPUT_PATH              Using custom output path. Ignores one in configuration file.
                                If you use this option, don't add the last directory separator.
                                If path not writable or doesn't exist will use Temp.     
USAGEMSG
;
}
sub printVersion
{
    print<<VERSIONMSG
Version of this copy of PocketNews is $VERSION, which includes:
PocketNews::Config      version : $PocketNews::Config::VERSION
PocketNews::DB          version : $PocketNews::DB::VERSION
PocketNews::NewsFetcher version : $PocketNews::NewsFetcher::VERSION
PocketNews::Weather     version : $PocketNews::Weather::VERSION  
VERSIONMSG
;
}

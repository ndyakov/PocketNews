#!/usr/bin/perl -s

=pod

=head1 PROJECT

PocketNews

=head1 USAGE

    perl PocketNews.pl -h

=head1 DESCRIPTION

A little bag of scripts that will build you a newspaper in epub format.

=head1 Subrotines

=cut

use strict;
use warnings;
no warnings 'once';
use PocketNews::Config;
use PocketNews::DB;
use PocketNews::NewsFetcher;
our $VERSION = '0.17';

MAIN:
{
    my $start = time
      if ( defined $::v or defined $::verbose );

    print "\n Executing PocketNews v$VERSION..."
      if ( defined $::v or defined $::verbose );

    printUsage() and exit(0) if ( defined $::h or defined $::help );
    printVersion() and exit(0) if defined $::version;

    my $cfg = PocketNews::Config->new;
    my $db  = PocketNews::DB->new( _filename => $cfg->get("dbfile") );

	$db->clearTable('news') if defined $::clean;

    my $nf  = PocketNews::NewsFetcher->new(
        _feeds => $cfg->get("rss"),
        _tags  => $cfg->get("tags")
    );

    my $location = $nf->getNewspaper( $cfg, $db );

    print "\n Your Newspaper is located at : $location \n";

    my $finish = time - $start
      if ( defined $::v or defined $::verbose );

    printf( " PocketNews executed for approximetly %02ds\n",
        int( $finish % 60 ) )
      if ( defined $::v or defined $::verbose );

}

=pod

=head2 printUsage

Prints a summary of the options.

=cut

sub printUsage {
    print <<USAGEMSG
Usage: perl PocketNews.pl [OPTION] [-c=CONFIG_FILE] [-O=OUTPUT_PATH]
      Option                        Meaning
    -h -help                    Help. Prints a summary of the options.
    -v -verbose                 Verbose. Prints usefull information while running.
    -version                    Prints the version of this copy.
    -clean                      Clean the table.
    -c=CONFIG_FILE              Using custom configuration file.
                                By default will use default.conf.
    -O=OUTPUT_PATH              Using custom output path. Ignores one in configuration file.
                                If you use this option, don't add the last directory separator.
                                If path not writable or doesn't exist will use Temp.
USAGEMSG
      ;
}

=pod

=head2 printVersion

Prints version information.

=cut

sub printVersion {
    print <<VERSIONMSG
The version of this copy of PocketNews is $VERSION, which includes:
PocketNews::Config              version : $PocketNews::Config::VERSION
PocketNews::DB                  version : $PocketNews::DB::VERSION
PocketNews::NewsFetcher         version : $PocketNews::NewsFetcher::VERSION
PocketNews::Weather             version : $PocketNews::Weather::VERSION
VERSIONMSG
      ;
}

=pod

=head1 AUTHOR

ndyakov

=cut

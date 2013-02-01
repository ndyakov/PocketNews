package PocketNews::Config;
=pod
=head1 NAME
 PocketNews::Config
=head1 SYNOPSIS
    my $cnf = PocketNews::Config->new(_args => \@ARGV);
=head1 DESCRIPTION
Config OOP wrapper
=head1 METHODS

=cut

use strict;
use warnings;
require XML::Simple;
use Cwd;
use File::Util qw( SL );
our $VERSION = '0.01';
=pod
=head2 new
      my $cnf = PocketNews::Config->new(_args => \@ARGV);;
=cut

sub new {
    my $class = shift;
    my $self  = bless { @_ }, $class;
    my $cfgfile;
    my $argvs = $self->{_args};
    if($#$argvs >= 0){ 
        $cfgfile = $$argvs[0];
    }else{ 
        $cfgfile = "default.conf";
    }
    $self->{_cfgfile} = $cfgfile;
    $self->{_cfg} = $self->_ReadConfig();
    return $self;
}

sub _ReadConfig{
    my $self = shift;
    my $xml = new XML::Simple;
    my $cfg = $xml->XMLin($self->{_cfgfile}, KeyAttr => { block => 'type' }, ValueAttr => ['value'], ForceArray => [ 'block', 'item', 'link']) or die("CONF FILE : $self->{_cfgfile} MISSING!");
    return $cfg if $self->_CheckConfig($cfg) or die("ERROR IN CONF FILE : $self->{_cfgfile}");
}
1; 
sub _CheckConfig{
    my $self = shift;
    my $cfg = shift;
    my $rss = $cfg->{block}->{rss}->{link} if defined $cfg->{block}->{rss}->{link};
    my $tags = $cfg->{block}->{tags}->{tag} if defined $cfg->{block}->{tags}->{tag};
    return 1 if (ref($cfg) eq 'HASH' && exists $cfg->{block}->{system} && exists $cfg->{block}->{system}->{DBFILE} 
    && ( $cfg->{block}->{system}->{WEATHER} eq 0 || ( $cfg->{block}->{system}->{WEATHER} eq 1 && $cfg->{block}->{system}->{LOCATION} ) ) && $#$tags >= 0 && $#$rss >= 0);
    return 0;
}
1;

sub get{
    my ($self,$key) = @_;
    my $switch = { 
                   'rss'            => sub { return $self->{_cfg}->{block}->{rss}->{link}; },
                   'tags'           => sub { return $self->{_cfg}->{block}->{tags}->{tag}; },
                   'dbfile'         => sub { return $self->{_cfg}->{block}->{system}->{DBFILE}; },
                   'weather'        => sub { return $self->{_cfg}->{block}->{system}->{WEATHER}; },
                   'template'       => sub { return $self->{_cfg}->{block}->{system}->{TEMPLATE}; },
                   'location'       => sub { return $self->{_cfg}->{block}->{system}->{LOCATION}; },
                   'title'          => sub { return $self->{_cfg}->{block}->{system}->{TITLE}; },
                   'language'       => sub { return $self->{_cfg}->{block}->{system}->{LANGUAGE}; },
                   'template_path'  => sub { return getcwd.SL.'PocketNews'.SL.'Templates'.SL.$self->get('template'); },
                   'temp_path'      => sub { return getcwd.SL.'PocketNews'.SL.'Temp'; },
                   'epub_path'      => sub { return $self->{_cfg}->{block}->{system}->{SAVEAT}; },
                   'bashorg'        => sub { return $self->{_cfg}->{block}->{system}->{BASHORGQUOTE}; },
                   'default'        => sub {
                                             my $key = shift;
                                             return $self->{_cfg}->{block}->{custom}->{$key} if $self->{_cfg}->{block}->{custom}->{$key};
                                             return 0;
                                            }
                  };
    return $switch->{$key} ? $switch->{$key}->() : $switch->{'default'}->($key);
}
1;
=pod
=head1 AUTHOR
ndyakov
=cut

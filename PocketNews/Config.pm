package PocketNews::Config;

=pod
=head1 NAME

PocketNews::Config

=head1 SYNOPSIS

    use PocketNews::Config;
    ...
    my $cnf = PocketNews::Config->new;

=head1 DESCRIPTION

Config OOP wrapper

=head1 METHODS

=cut

use strict;
use warnings;
use XML::Simple;
use Cwd;
use File::Util qw( SL );
our $VERSION = '0.04';

=pod

=head2 new

=over 1

=item Usage

C<< my $cnf = PocketNews::Config->new; >>

=back

=cut

sub new {
    my $class = shift;
    
    print "\n Executing $class v$VERSION..."
      if ( defined $::v or defined $::verbose );
      
    my $self = bless {@_}, $class;
    my $cfgfile;
    if ( defined $::c ) 
    {
        $cfgfile = $::c;
    }
    else 
    {
        $cfgfile = "default.conf";
    }
    $self->{_cfgfile} = $cfgfile;
    $self->{_cfg}     = $self->_ReadConfig();
    return $self;
}
=pod

=head2 get

=over 3

=item Description

Method that will get some value from the loaded configuration,
coresponding to the C<$key> parameter.

=item Usage

C<< my $value = $cfg->get($key); >>

=item Return

Returns scalar the value of that key, or 0 if none found.

=back

=cut

sub get {
    my ( $self, $key ) = @_;
    my $switch = 
    {
        'rss'    => 
            sub { return $self->{_cfg}->{block}->{rss}->{link}; },
        'tags'   => 
            sub { return $self->{_cfg}->{block}->{tags}->{tag}; },
        'dbfile' => 
            sub { return $self->{_cfg}->{block}->{system}->{DBFILE}; },
        'weather' =>
            sub { return $self->{_cfg}->{block}->{system}->{WEATHER}; },
        'template' =>
            sub { return $self->{_cfg}->{block}->{system}->{TEMPLATE}; },
        'location' =>
            sub { return $self->{_cfg}->{block}->{system}->{LOCATION}; },
        'title' => 
            sub { return $self->{_cfg}->{block}->{system}->{TITLE}; },
        'language' =>
            sub { return $self->{_cfg}->{block}->{system}->{LANGUAGE}; },
        'template_path' => 
            sub {
                return getcwd 
                 . SL
                 . 'PocketNews'
                 . SL
                 . 'Templates'
                 . SL
                 . $self->get('template');
                },
        'temp_path' => 
            sub { return getcwd . SL . 'PocketNews' . SL . 'Temp'; },
        'epub_path' =>
            sub { return $self->{_cfg}->{block}->{system}->{SAVEAT}; },
        'bashorg' =>
            sub { return $self->{_cfg}->{block}->{system}->{BASHORGQUOTE}; },
        'default' => 
            sub {
              my $name = shift;
              return $self->{_cfg}->{block}->{custom}->{$name}
                 ? $self->{_cfg}->{block}->{custom}->{$name}
               : 0;
              }
    };
    return $switch->{$key} ? $switch->{$key}->() : $switch->{'default'}->($key);
}
1;
=pod

=head2 _ReadConfig

=over 3

=item Description

B<PRIVATE> - Should be use only by this class methods.

This method reads the configuration file.

=item Usage

C<< $self{_cfg} = $self->_ReadConfig; >>

=item Return

Returns reference to an hash with parsed file.

=back

=cut

sub _ReadConfig {
    my $self = shift;
    
    print "\n Reading Configuration file $self->{_cfgfile}..."
      if ( defined $::v or defined $::verbose );
      
    my $xml = new XML::Simple;
    my $cfg = $xml->XMLin(
        $self->{_cfgfile},
        KeyAttr   => { block => 'type' },
        ValueAttr => ['value'],
        ForceArray => [ 'block', 'item', 'link' ]
    ) or die("CONF FILE : $self->{_cfgfile} MISSING!");
    
    print "done." 
      if ( defined $::v or defined $::verbose );
    
    return $cfg
      if $self->_CheckConfig($cfg)
          or die("ERROR IN CONF FILE : $self->{_cfgfile}");
}
1;
=pod

=head2 _CheckConfig

=over 3

=item Description

B<PRIVATE> - Should be use only by this class methods.

This method checks the parsed configuration for critical errors.

=item Usage

C<< dosomething if $self->_CheckConfig($cfg) >>

=item Return

Returns 0 if the configurations is BAD or 1 if it is GOOD.

=back

=cut

sub _CheckConfig {
    my $self = shift;
    my $cfg  = shift;
    
    print "\n Checking Configuration file $self->{_cfgfile}..."
      if ( defined $::v or defined $::verbose );
      
    my $rss = $cfg->{block}->{rss}->{link}
      if defined $cfg->{block}->{rss}->{link};
    my $tags = $cfg->{block}->{tags}->{tag}
      if defined $cfg->{block}->{tags}->{tag};
      
    print "done."
      if ( defined $::v or defined $::verbose );
    
    return 1
      if (
           ref($cfg) eq 'HASH'
        && exists $cfg->{block}->{system}
        && exists $cfg->{block}->{system}->{DBFILE}
        && (
            $cfg->{block}->{system}->{WEATHER} eq 0
            || (   $cfg->{block}->{system}->{WEATHER} eq 1
                && $cfg->{block}->{system}->{LOCATION} )
        )
        && $#$tags >= 0
        && $#$rss >= 0
      );
      
    print "\n Error in Configuration file $self->{_cfgfile}..."
      if ( defined $::v or defined $::verbose );
      
    return 0;
}
1;

=pod

=head1 AUTHOR

ndyakov

=cut

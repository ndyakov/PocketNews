package PocketNews::Weather;

=pod

=head1 NAME

PocketNews::Weather

=head1 SYNOPSIS

    use PocketNews::Weather; 
    ...
    my $weather = PocketNews::Weather->new(
                    _location => 'Sofia, Bulgaria'
                );

=head1 DESCRIPTION

Module that should get weather forecast
for a specific location.

=head1 METHODS

=cut

use strict;
use warnings;
use Yahoo::Weather;
our $VERSION = '0.02';

=pod

=head2 new

=over 1

=item Usage

    my $weather = PocketNews::Weather->new(
                    _location => 'Sofia, Bulgaria'
                ); 

=back

=cut

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;
    my $yw    = Yahoo::Weather->new();
    $self->{_yw} = $yw->getWeatherByLocation( $self->{_location} );
    return $self;
}

=pod

=head2 getWeather

=over 3

=item Description

Gets the weather and prepares it for TMPL_LOOP.

=item Usage

C<< ...WEATHER_LOOP => $weather->getWeather(),... >>

=item Return

Returns reference to an array of hash references.

=back

=cut

sub getWeather {
    my $self = shift;
    my @result;
    my $forecast = $self->{_yw}->{TwoDayForecast};
    foreach my $day (@$forecast) {
        my %temp;
        $temp{WEATHER_DATE}      = $day->{day} . ' ' . $day->{date};
        $temp{WEATHER_CONDITION} = $day->{text};
        $temp{WEATHER_TEMP} = $day->{low} . '°C | ' . $day->{high} . '°C';
        push @result, \%temp;
    }
    return \@result;
}
1;

=pod

=head1 AUTHOR

ndyakov

=cut

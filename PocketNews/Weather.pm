package PocketNews::Weather;

use strict;
use warnings;
use Yahoo::Weather;

=pod
=head2 new
  my $nf = PocketNews::NewsFetcher(_location => 'Sofia, Bulgaria');
=cut


sub new {
    my $class = shift;
    my $self  = bless { @_ }, $class;
    my $yw = Yahoo::Weather->new();
    $self->{_yw} = $yw->getWeatherByLocation($self->{_location});
    return $self;
}

sub getWeather{
    my $self = shift;
    my @result;
    my $forecast = $self->{_yw}->{TwoDayForecast};
    foreach my $day (@$forecast)
    {
        my %temp;
        $temp{WEATHER_DATE} = $day->{day}.' '.$day->{date};
        $temp{WEATHER_CONDITION} = $day->{text};
        $temp{WEATHER_TEMP} = $day->{low}.'°C | '.$day->{high}.'°C';
        push @result, \%temp;
    }
    return \@result;
}
1;

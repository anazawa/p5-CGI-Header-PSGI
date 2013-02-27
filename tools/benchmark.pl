use strict;
use warnings;
use Benchmark qw/cmpthese/;
use CGI::Cookie;
use CGI::PSGI;
use Data::Dumper;

package CGI::PSGI::Extended;
use Moo;
extends 'CGI::PSGI';
with 'CGI::Header::PSGI';

sub crlf { $CGI::CRLF }

package main;

my $cookie1 = CGI::Cookie->new( -name => 'foo', -value => 'bar' );
my $cookie2 = CGI::Cookie->new( -name => 'bar', -value => 'baz' );
my $cookie3 = CGI::Cookie->new( -name => 'baz', -value => 'qux' );

my @args = (
    -NPH           => 1,
    expires        => '+3M',
    -attachment    => 'genome.jpg',
    -window_target => 'ResultsWindow',
    Cookies        => [ $cookie1, $cookie2, $cookie3 ],
    -type          => 'text/plain',
    -Charset       => 'utf-8',
    -p3p           => [qw/CAO DSP LAW CURa/],
);

my $env = \%ENV;

cmpthese(-1, {
    'CGI::PSGI' => sub {
        my $cgi = CGI::PSGI->new( $env );
        my ( $status, $headers ) = $cgi->psgi_header( @args );
    },
    'CGI::Header::PSGI' => sub {
        my $cgi = CGI::PSGI::Extended->new( $env );
        my ( $status, $headers ) = $cgi->psgi_header( @args );
    },
});

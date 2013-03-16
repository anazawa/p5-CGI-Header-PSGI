use strict;
use warnings;
use feature qw/say/;
use Benchmark qw/cmpthese/;
use CGI::Cookie;
use CGI::PSGI;

package CGI::PSGI::Extended;
use Moo;
extends 'CGI';
with 'CGI::Header::PSGI';

sub crlf { $CGI::CRLF }

package CGI::Simple::PSGI;
use Moo;
extends 'CGI::Simple';
with 'CGI::Header::PSGI';

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

my $env = {};

cmpthese(-1, {
    'CGI::PSGI' => sub {
        my $cgi = CGI::PSGI->new( $env );
        my ( $status, $headers ) = $cgi->psgi_header( @args );
    },
    'CGI::Header::PSGI' => sub {
        my $cgi = CGI::PSGI::Extended->new;
        my ( $status, $headers ) = $cgi->psgi_header( @args );
    },
    'CGI::Simple::PSGI' => sub {
        my $cgi = CGI::Simple::PSGI->new;
        my ( $status, $headers ) = $cgi->psgi_header( @args );
    },
});

cmpthese(-1, {
    'CGI::PSGI' => sub {
        my $cgi = CGI::PSGI->new( $env );
        my ( $status, $headers ) = $cgi->psgi_redirect( @args );
    },
    'CGI::Header::PSGI' => sub {
        my $cgi = CGI::PSGI::Extended->new;
        my ( $status, $headers ) = $cgi->psgi_redirect( @args );
    },
    'CGI::Simple::PSGI' => sub {
        my $cgi = CGI::Simple::PSGI->new;
        my ( $status, $headers ) = $cgi->psgi_redirect( @args );
    },
});

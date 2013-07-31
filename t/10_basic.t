use strict;
use warnings;
use CGI::Header::PSGI;
use Test::More tests => 3;

my $header = CGI::Header::PSGI->new(
    header => {
        '-Status'       => '404 Not Found',
        '-Content_Type' => 'text/plain',
    },
);

can_ok $header, qw( has_status status_code );

my ( $status, $headers ) = $header->finalize;

is $status, 404;
is_deeply $headers, [ 'Content-Type', 'text/plain; charset=ISO-8859-1' ];

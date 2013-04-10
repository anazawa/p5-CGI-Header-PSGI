# copied and rearranged from CGI::PSGI's redirect.t

use strict;
use warnings;
use Test::More;
use CGI::PSGI;
use CGI::Header::PSGI;

eval "use 5.008";
plan skip_all => "$@" if $@;
plan tests => 6;
#plan 'no_plan';

# Set up a CGI environment
my $env;
$env->{REQUEST_METHOD}  = 'GET';
$env->{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$env->{PATH_INFO}       = '/somewhere/else';
$env->{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$env->{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$env->{SERVER_PROTOCOL} = 'HTTP/1.0';
$env->{SERVER_PORT}     = 8080;
$env->{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$env->{REQUEST_URI}     = "$env->{SCRIPT_NAME}$env->{PATH_INFO}?$env->{QUERY_STRING}";
$env->{HTTP_LOVE}       = 'true';

my $header = CGI::Header::PSGI->new(
    handler => 'redirect',
    query => CGI::PSGI->new($env),
);


# These first tree tests are ported from CGI.pm's 'function.t'
{
    my $test = 'psgi_redirect($url)';
    $header->clear->location('http://somewhere.else');
    is($header->status_code, 302, "$test - default status");
    is_deeply $header->as_arrayref, [ 'Location' => 'http://somewhere.else' ], "$test - headers array";  
}
{
    my $test = 'psgi_redirect() with content type';
    $header->clear->location('http://somewhere.else')->type('text/html');
    is($header->status_code, 302, "$test - status");
    is_deeply $header->as_arrayref, [
        'Location' => 'http://somewhere.else',
        'Content-Type' => 'text/html; charset=ISO-8859-1',
    ], "$test - headers array";  
}
{
    my $test = "psgi_redirect() with path and query string"; 
    $header->clear->location('http://somewhere.else/bin/foo&bar')->type('text/html');
    is($header->status_code, 302, "$test - status");
    is_deeply $header->as_arrayref, [
        'Location' => 'http://somewhere.else/bin/foo&bar',
        'Content-Type' => 'text/html; charset=ISO-8859-1',
    ], "$test - headers array";  
}



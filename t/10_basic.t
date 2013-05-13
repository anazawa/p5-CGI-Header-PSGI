use strict;
use warnings;
use Test::MockTime qw/set_fixed_time/;
use CGI::Cookie;
use CGI::Header::PSGI;
use Test::More tests => 4;

local $ENV{SERVER_SOFTWARE} = 'Apache/1.3.27 (Unix)';

set_fixed_time( 1341637509 );

my $header = CGI::Header::PSGI->new(
    header => {
        '-Status'        => '304 Not Modified',
        '-Content_Type'  => 'text/plain',
        '-Charset'       => 'utf-8',
        '-Attachment'    => 'genome.jpg',
        '-P3P'           => [qw/CAO DSP LAW CURa/],
        '-Window_Target' => 'ResultsWindow',
        '-Expires'       => '+3d',
        '-Foo_Bar'       => 'baz',
        '-Set_Cookie'    => [ CGI::Cookie->new(ID => 123456) ],
    },
);

is $header->status_code, 304;

is_deeply $header->as_arrayref, [
    'Window-Target',       'ResultsWindow',
    'P3P',                 'policyref="/w3c/p3p.xml", CP="CAO DSP LAW CURa"',
    'Set-Cookie',          'ID=123456; path=/',
    'Expires',             'Tue, 10 Jul 2012 05:05:09 GMT',
    'Date',                'Sat, 07 Jul 2012 05:05:09 GMT',
    'Content-Disposition', 'attachment; filename="genome.jpg"',
    'Foo-bar',             'baz',
    'Content-Type',        'text/plain; charset=utf-8',
];

is $header->status('404 Not Found'), $header;
is $header->status_code, '404';

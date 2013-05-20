package CGI::Header::PSGI;
use 5.008_009;
use strict;
use warnings;
use parent 'CGI::Header';
use Carp qw/croak/;

our $VERSION = '0.54001';

sub new {
    my $class  = shift;
    my $self   = $class->SUPER::new( @_ );
    my $header = $self->header;

    if ( exists $header->{status} ) {
        my $status = delete $header->{status};
        $self->{status} = $status if !exists $self->{status};
    }

    $self;
}

sub status {
    my $self = shift;
    return $self->{status} unless @_;
    $self->{status} = shift;
    $self;
}

sub status_code {
    my $self = shift;
    my $code = $self->{status} || '200';
    $code =~ s/\D*$//;
    $code;
}

sub as_arrayref {
    my $self   = shift;
    my $query  = $self->query;
    my %header = %{ $self->header };
    my $nph    = delete $header{nph} || $query->nph;

    my ( $attachment, $charset, $cookies, $expires, $p3p, $status, $target, $type )
        = delete @header{qw/attachment charset cookies expires p3p status target type/};

    my @headers;

    push @headers, 'Server', $query->server_software if $nph;
    push @headers, 'Status', $status if $status;
    push @headers, 'Window-Target', $target if $target;

    if ( $p3p ) {
        my $tags = ref $p3p eq 'ARRAY' ? join ' ', @{$p3p} : $p3p;
        push @headers, 'P3P', qq{policyref="/w3c/p3p.xml", CP="$tags"};
    }

    my @cookies = ref $cookies eq 'ARRAY' ? @{$cookies} : $cookies;
       @cookies = map { $self->_bake_cookie($_) || () } @cookies;

    push @headers, map { ('Set-Cookie', $_) } @cookies;
    push @headers, 'Expires', $self->_date($expires) if $expires;
    push @headers, 'Date', $self->_date if $expires or @cookies or $nph;
    push @headers, 'Pragma', 'no-cache' if $query->cache;

    if ( $attachment ) {
        my $value = qq{attachment; filename="$attachment"};
        push @headers, 'Content-Disposition', $value;
    }

    push @headers, map { ucfirst $_, $header{$_} } keys %header;

    unless ( defined $type and $type eq q{} ) {
        my $value = $type || 'text/html';
        $charset = $query->charset if !defined $charset;
        $value .= "; charset=$charset" if $charset && $value !~ /\bcharset\b/;
        push @headers, 'Content-Type', $value;
    }

    \@headers;
}


sub _bake_cookie {
    my ( $self, $cookie ) = @_;
    ref $cookie eq 'CGI::Cookie' ? $cookie->as_string : $cookie;
}

sub _date {
    my ( $self, $expires ) = @_;
    CGI::Util::expires( $expires, 'http' );
}

sub finalize {
    my $self    = shift;
    my $status  = $self->status_code;
    my $headers = $self->as_arrayref;
    my $crlf    = $self->_crlf;

    my @headers;
    for ( my $i = 0; $i < @$headers; $i += 2 ) {
        my $field = $headers->[$i];
        my $value = $headers->[$i+1];

        # CR escaping for values, per RFC 822:
        # > Unfolding is accomplished by regarding CRLF immediately
        # > followed by a LWSP-char as equivalent to the LWSP-char.
        $value =~ s/$crlf(\s)/$1/g;

        # All other uses of newlines are invalid input.
        if ( $value =~ /$crlf|\015|\012/ ) {
            # shorten very long values in the diagnostic
            $value = substr($value, 0, 72) . '...' if length $value > 72;
            croak "Invalid header value contains a newline not followed by whitespace: $value";
        }

        push @headers, $field, $value;
    }

    $status, \@headers;
}

sub _crlf {
    $CGI::CRLF;
}

1;

__END__

=head1 NAME

CGI::Header::PSGI - Generate PSGI-compatible response header arrayref

=head1 SYNOPSIS

  use CGI::PSGI;
  use CGI::Header::PSGI;

  my $app = sub {
      my $env    = shift;
      my $query  = CGI::PSGI->new( $env );
      my $header = CGI::Header::PSGI->new( query => $query );
        
      my $body = do {
          # run CGI.pm-based application
      };

      return [
          $header->status_code,
          $header->as_arrayref,
          [ $body ]
      ];
  };

=head1 VERSION

This document refers to CGI::Header::PSGI 0.14.

=head1 DESCRIPTION

This module can be used to convert CGI.pm-compatible HTTP header properties
into L<PSGI> response header array reference. 

This module requires your query class is orthogonal to a global variable
C<%ENV>. For example, L<CGI::PSGI> adds the C<env>
attribute to CGI.pm, and also overrides some methods which refer to C<%ENV>
directly. This module doesn't solve those problems at all.

=head2 METHODS

This class inherits all methods from L<CGI::Header>.

Adds the following methods to the superclass:

=over 4

=item $header->status_code

Returns HTTP status code.

=item $headers = $header->as_arrayref

Returns PSGI response header array reference.

=back

Overrides the following method of the superclass:

=over 4

=item ($status_code, $headers) = $header->finalize

Return the status code and PSGI header array reference of this response.

=back

=head1 SEE ALSO

L<CGI::Emulate::PSGI>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut


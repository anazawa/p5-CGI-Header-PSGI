package CGI::Header::PSGI;
use 5.008_009;
use strict;
use warnings;
use parent 'CGI::Header::Standalone';

our $VERSION = '0.13';

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
    my $self    = shift;
    my $headers = $self->_finalize->{headers};

    my @headers;
    for ( my $i = 0; $i < @$headers; $i += 2 ) {
        my ($field, $value) = @{$headers}[$i, $i+1];
        push @headers, $field, $self->_process_newline($value);
    }

    \@headers;
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
into PSGI response header array reference. 

This module requires your query class is orthogonal to a global variable
C<%ENV>. For example, L<CGI::PSGI> adds the C<env>
attribute to CGI.pm, and also overrides some methods which refer to C<%ENV>
directly. This module doesn't solve those problems at all.

=head2 METHODS

This class adds the following methods to L<CGI::Header>:

=over 4

=item $header->status_code

Returns HTTP status code.

=item $header->as_arrayref

Returns PSGI response header array reference.

=back

=head1 SEE ALSO

L<CGI::Emulate::PSGI>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut


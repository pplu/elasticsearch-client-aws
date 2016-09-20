package Search::Elasticsearch::Cxn::AmazonES;
# This is basically Search::Elasticsearch::Cxn::HTTPTiny with
# AWS signing in it.

$Search::Elasticsearch::Cxn::AmazonES::VERSION = '0.02';
use Moo;
with 'Search::Elasticsearch::Role::Cxn::HTTP',
    'Search::Elasticsearch::Role::Cxn',
    'Search::Elasticsearch::Role::Is_Sync';

use Net::Amazon::Signature::V4;
use HTTP::Request;
use HTTP::Headers;
use POSIX qw(strftime);

use HTTP::Tiny 0.043 ();
use namespace::clean;

my $Cxn_Error = qr/ Connection.(?:timed.out|re(?:set|fused))
                       | connect:.timeout
                       | Host.is.down
                       | No.route.to.host
                       | temporarily.unavailable
                       /x;

has aws_sign_class => (is => 'ro', default => 'Net::Amazon::Signature::V4');
has region => (is => 'ro', required => 1);
has credentials => (is => 'ro', required => 1, isa => sub { 
  die "Credentials needs to have an access_key method" if (not $_[0]->can('access_key'));
  die "Credentials needs to have an secret_key method" if (not $_[0]->can('secret_key'));
  die "Credentials needs to have a session_token method" if (not $_[0]->can('session_token'));
});

#===================================
sub perform_request {
#===================================
    my ( $self, $params ) = @_;
    my $uri    = $self->build_uri($params);
    my $method = $params->{method};

    my %args;
    if ( defined $params->{data} ) {
        $args{content} = $params->{data};
        $args{headers}{'Content-Type'} = $params->{mime_type};
    }

    $args{headers}{Date} = strftime( '%Y%m%dT%H%M%SZ', gmtime );
    $args{headers}{Host} = $uri->host;

    if ($self->credentials->session_token) {
      $args{headers}{'X-Amz-Security-Token'} = $self->credentials->session_token;
    }

    my $sig = $self->aws_sign_class->new(
      $self->credentials->access_key,
      $self->credentials->secret_key,
      $self->region,
      'es'
    );

    my $req = HTTP::Request->new(
      $params->{ method },
      $uri,
      HTTP::Headers->new(%{ $args{headers} }),
      $args{content}
    );
    $sig->sign($req);

    $args{headers}{Authorization} = $req->header('Authorization');
    delete $args{headers}{Host};

    my $handle = $self->handle;
    $handle->timeout( $params->{timeout} || $self->request_timeout );

    my $response = $handle->request( $method, "$uri", \%args );

    return $self->process_response(
        $params,                 # request
        $response->{status},     # code
        $response->{reason},     # msg
        $response->{content},    # body
        $response->{headers}     # headers
    );
}

#===================================
sub error_from_text {
#===================================
    local $_ = $_[2];
    return
          /[Tt]imed out/             ? 'Timeout'
        : /Unexpected end of stream/ ? 'ContentLength'
        : /SSL connection failed/    ? 'SSL'
        : /$Cxn_Error/               ? 'Cxn'
        :                              'Request';
}

#===================================
sub _build_handle {
#===================================
    my $self = shift;
    my %args = ( default_headers => $self->default_headers );
    if ( $self->is_https && $self->has_ssl_options ) {
        $args{SSL_options} = $self->ssl_options;
        if ( $args{SSL_options}{SSL_verify_mode} ) {
            $args{verify_ssl} = 1;
        }
    }

    return HTTP::Tiny->new( %args, %{ $self->handle_args } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Cxn::AmazonES - A Cxn implementation to connect to Amazon ES clusters

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Provides a Cxn class that is able to connect to Elasticsearch clusters provisioned by the
Amazon Web Services Elasticsearch (ES) service. It uses L<HTTP::Tiny> to perform the requests,
signing them with AWS v4 signatures.

This backend is based on the implmentation of the L<Search::Elasticsearch::Cxn::HTTPTiny> module,
only adding the ability to sign requests with AWS credentials.

See L<Paws::ES> for information provisioning and modifying Amazon ES clusters via the administrative
API

=head1 SYNOPSIS

  use Search::ElasticSearch;

  my $c = Search::Elasticsearch->new(
    nodes  => [ 'es_endpoint' ],
    cxn    => 'AmazonES',
    region => 'eu-west-1',
    credentials => $creds
  );

=head1 CONFIGURATION

=head2 C<region>

Region where the ES cluster is provisioned

=head2 C<credentials>

Any object that has methods C<access_key>, C<secret_key> and C<session_token>.

session_token must return undef if there is no session token.

With this distribution, you can find L<Search::Elasticsearch::Cxn::AmazonES::Credentials>,
which will help you instance an object with those methods, but you can really pass in any
object you want. One that may be interesting are L<Paws> credential objects. The same objects
that Paws uses to authenticate can be used with L<Search::Elasticsearch>. See the examples
directory for code that uses this capability to integrate with Paws.

  my $paws = Paws->new;
  my $c = Search::Elasticsearch->new(
    ...
    credentials => $paws->config->credentials,
    ...
  );

=head2 Inherited configuration

See L<Search::Elasticsearch::Cxn::HTTPTiny> for inherited configurations

=head1 SSL/TLS

See L<Search::Elasticsearch::Cxn::HTTPTiny> for SSL information

=head1 SEE ALSO

=over

=item * L<Search::Elasticsearch::Cxn::HTTPTiny>

=item * L<Search::Elasticsearch>

=back

=head1 AUTHOR

Original HTTP Cxn code by Clinton Gormley <drtech@cpan.org>

Adapted to AmazonES by Jose Luis Martinez Torres <joseluis.martinez@capside.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by CAPSiDE

Original code by Elasticsearch BV.

=head1 LICENSE

  Apache 2.0 License

=cut

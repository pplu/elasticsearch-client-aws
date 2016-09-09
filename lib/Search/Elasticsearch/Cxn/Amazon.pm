package Search::Elasticsearch::Cxn::Amazon;
$Search::Elasticsearch::Cxn::Amazon::VERSION = '2.03';
use Moo;
with 'Search::Elasticsearch::Role::Cxn::HTTP',
    'Search::Elasticsearch::Role::Cxn',
    'Search::Elasticsearch::Role::Is_Sync';

use HTTP::Tiny 0.043 ();
use namespace::clean;

my $Cxn_Error = qr/ Connection.(?:timed.out|re(?:set|fused))
                       | connect:.timeout
                       | Host.is.down
                       | No.route.to.host
                       | temporarily.unavailable
                       /x;

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

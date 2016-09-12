#!/usr/bin/env perl

use Search::Elasticsearch;
use Data::Dumper;
use FindBin;

package ESCreds {
  use Moo;
  has access_key => (is => 'ro', required => 1, default => sub { $ENV{ ACCESS_KEY } });
  has secret_key => (is => 'ro', required => 1, default => sub { $ENV{ SECRET_KEY } });
}

my $host = $ARGV[0] or die "Usage: $0 HOST";

use lib "$FindBin::Bin/../lib";

my $c = Search::Elasticsearch->new(
  cxn_pool => 'Static',
  nodes => [ $host ],
  cxn => 'AmazonES',
  region => 'eu-west-1',
  credentials => ESCreds->new,
);

my $results = $c->search(
  index => 'my_index',
  type => 'type',
  body => {
    query => { 
      match => { my => 'document' }
    }
  }
);
print Dumper($results);



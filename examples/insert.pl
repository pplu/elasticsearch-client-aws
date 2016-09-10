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
  #cxn_pool => 'Static::NoPing',
  #cxn_pool => 'Sniff',
  cxn_pool => 'Static',
  nodes => [ $host ],
  cxn => 'Amazon',
  region => 'eu-west-1',
  credentials => ESCreds->new,
);

foreach my $i (1..100) {
  $c->create(
    index => 'my_index',
    type  => 'type',
    id    => "$i",
    body  => { my => "document $i",
               number => $i
             }
   );
}


#!/usr/bin/env perl

use Search::Elasticsearch;
use Data::Dumper;
use FindBin;

my $host = $ARGV[0] or die "Usage: $0 HOST";

use lib "$FindBin::Bin/../lib";

use Search::Elasticsearch::Cxn::AmazonES::Credentials;

my $c = Search::Elasticsearch->new(
  #cxn_pool => 'Static::NoPing',
  #cxn_pool => 'Sniff',
  cxn_pool => 'Static',
  nodes => [ $host ],
  cxn => 'AmazonES',
  region => 'eu-west-1',
  credentials => Search::Elasticsearch::Cxn::AmazonES::Credentials->new(
    access_key => $ENV{ ACCESS_KEY },
    secret_key => $ENV{ SECRET_KEY },
  ),
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


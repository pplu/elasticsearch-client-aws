#!/usr/bin/env perl

use Search::Elasticsearch;
use Data::Dumper;
use FindBin;
use Paws;

my $host = $ARGV[0] or die "Usage: $0 HOST";

use lib "$FindBin::Bin/../lib";

my $paws = Paws->new;

my $c = Search::Elasticsearch->new(
  #cxn_pool => 'Static::NoPing',
  #cxn_pool => 'Sniff',
  cxn_pool => 'Static',
  nodes => [ $host ],
  cxn => 'Amazon',
  region => 'eu-west-1',
  credentials => $paws->config->credentials,
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



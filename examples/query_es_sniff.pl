#!/usr/bin/env perl

warn "Watch out!!! Sniff cxn_pool doesn't work with AmazonES";

use Search::Elasticsearch;
use Data::Dumper;
use FindBin;
use Paws;
use Paws::Credential::STS;

my $host = $ARGV[0] or die "Usage: $0 HOST";

use lib "$FindBin::Bin/../lib";

my $paws = Paws->new( config => {
  credentials => Paws::Credential::STS->new(
    Name => 'es-test-sts',
    Policy => '{"Version": "2012-10-17","Statement": {"Effect": "Allow","Action": "*", "Resource": "*" } }',
  ),
});

my $c = Search::Elasticsearch->new(
  trace_to => 'Stderr',
  cxn_pool => 'Sniff',
  nodes => [ $host ],
  cxn => 'AmazonES',
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



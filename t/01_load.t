#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('Search::Elasticsearch::Cxn::AmazonES');
use_ok('Search::Elasticsearch::Cxn::AmazonES::Credentials');

done_testing;

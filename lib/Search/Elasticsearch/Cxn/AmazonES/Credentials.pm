package Search::Elasticsearch::Cxn::AmazonES::Credentials;
  use Moo;

  has access_key => (is => 'ro', required => 1);
  has secret_key => (is => 'ro', required => 1);
  has session_token => (is => 'ro');

1;

package WWW::VastAI::HTTPResponse;

use Moo;

has status  => ( is => 'ro', required => 1 );
has content => ( is => 'ro', default  => sub { '' } );

1;

package WWW::VastAI::HTTPRequest;

use Moo;

has method  => ( is => 'ro', required => 1 );
has url     => ( is => 'ro', required => 1 );
has headers => ( is => 'ro', default  => sub { {} } );
has content => ( is => 'ro' );

sub has_content { defined shift->content }

1;

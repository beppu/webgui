package WebGUI::Session::Rest;
use WebGUI::BestPractices;
use WebGUI::International;
use JSON;
use Moose;

has 'status' => ( is => 'rw', isa => 'Int', default => 200 );

=head2 session

A WebGUI::Session object. Required.

=cut

has 'session' => (
   is       => 'rw',
   required => 1,
   weak_ref => 1
);

sub response{
   my $this = shift;
   my $data = shift || {};
   $this->session->response->status( $this->status );
   my $callback = $this->session->request->param('callback');
   if ( $callback ){
      $this->session->response->headers({ 'Access-Control-Allow-Origin' => '*',
                                          'Access-Control-Allow-Methods' => 'GET',
                                          'Content-Type' => 'application/javascript' });
      return qq|$callback(| . to_json( $data ) . ');';
      
   }else{
      $this->session->response->content_type("application/json");
      return to_json( $data );
      
   }
 
}
# Cleanup ---
after 'response'  => sub { 
   my $this = shift;
   $this->status( 200 ); 
   $this->session(undef);
};

sub created{
   my $this = shift;
   my $data = shift;
   $this->status(201);
   
   $this->response( $data );     
}

sub deleted{
   my $this = shift;
   $this->response({});     
}

sub forbidden{
   my $this = shift;
   my $data = shift;
   $this->status(403);
   
   $this->response( $data );  
}

sub notFound{
   my $this = shift;
   my $data = shift;
   $this->status(404);
   
   $this->response( $data );  
}

sub notModified{
   my $this = shift;
   my $data = shift;
   $this->status(304);
   
   $this->response( $data );  
}

sub unauthorized{
   my $this = shift;
   my $data = shift;
   $this->status(401);
   
   $this->response( $data );
}

sub vitalComponent{
   my $this = shift;
   my $i18n = WebGUI::International->new($this->session);
   my $message = $i18n->get(40). ' ' . $i18n->get(41);
   return $this->forbidden({ message => $message });
}


__PACKAGE__->meta->make_immutable;

1;

__END__

HTTP Codes (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html):
   200 OK
   201 Created
   202 Accepted
   303 See Other
   304 Not Modified
   400 Bad Request
   401 Unauthorized
   403 Forbidden
   404 Not Found
   409 Conflict
   500 Internal Server Error
   501 Not Implemented
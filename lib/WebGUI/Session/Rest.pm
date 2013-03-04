package WebGUI::Session::Rest;
use WebGUI::BestPractices;
use JSON;
use Moose;

has 'error'     => ( is => 'rw', isa => 'Str' );
has 'message'   => ( is => 'rw', isa => 'Str' );
has 'status'    => ( is => 'rw', isa => 'Int', default => 200 );
has 'data'      => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

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
   $this->data->{error}   = $this->error   if $this->error;
   $this->data->{message} = $this->message if $this->message;
   
   $this->session->response->content_type("application/json");
   $this->session->response->status( $this->status );
   
   return to_json $this->data;
   
}
# Cleanup ---
after 'response'  => sub { 
   my $this = shift;
   $this->error("");
   $this->message("");
   $this->status( 200 );   
   $this->data({});   
   $this->session(undef);
};

sub created{
   my $this = shift;
   $this->status(201);
   
   $this->response;     
}

sub deleted{
   my $this = shift;
   $this->data({});
   
   $this->response;     
}

sub forbidden{
   my $this = shift;
   $this->status(403);
   
   $this->response;  
}

sub notFound{
   my $this = shift;
   $this->status(404);
   
   $this->response;  
}

sub notModified{
   my $this = shift;
   $this->status(304);
   
   $this->response;  
}

sub unauthorized{
   my $this = shift;
   $this->status(401);
   
   $this->response;
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
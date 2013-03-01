package WebGUI::Operation::ActiveSessions;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::AdminConsole;
use WebGUI::International;
use WebGUI::Paginator;
use WebGUI::SQL;
use JSON;

=head1 NAME

Package WebGUI::Operations::ActiveSessions

=head1 DESCRIPTION

Operation handler for displaying and killing active sessions.

=cut

#----------------------------------------------------------------------------

=head2 canView ( session [, user] )

Returns true if the given user is allowed to use this operation. user must be
a WebGUI::User object. By default, checks the current user.

=cut

sub canView {
    my $session     = shift;
    my $user        = shift || $session->user;
    return $user->isInGroup( $session->setting->get("groupIdAdminActiveSessions") );
}

#-------------------------------------------------------------------

=head2 www_killSession ( )

This method can be called directly, but is usually called
from www_viewActiveSessions. It ends the active session in
$session->form->process("sid").  Afterwards, it calls www_viewActiveSessions.

=cut

sub www_killSession { 
   my $session = shift;
   my $i18n = WebGUI::International->new($session);
   $session->response->content_type("application/json");
   # should not delete our own session
   if ( $session->form->process("sid") eq $session->getId ){
      $session->response->status(304);
      return to_json { header => $i18n->get(108)->{message}, error => $i18n->get(36) };

   # delete the session
   }elsif ( canView($session) ){ # && $session->request->method eq 'DELETE'
      $session->db->deleteRow("userSession","sessionId",$session->form->process("sid"));
      $session->db->deleteRow("userSessionScratch","sessionId",$session->form->process("sid"));
	   return to_json { }; # json success

   # Permission denied
   }else{
      $session->response->status(403);
      return to_json { header => $i18n->get(35), error => $i18n->get(36) };#return $self->session->style->userStyle($output);
      
   }   

}

#-------------------------------------------------------------------

=head2 www_viewActiveSessions ( )

Display a list of all active user sessions, along with an icon to
delete (kill) each one via www_killSession

=cut

sub www_viewActiveSessions {
   my $session = shift;
   my $i18n = WebGUI::International->new($session);
   $session->response->content_type("application/json");
   my $webParams = $session->request->parameters->mixed;
   if ( canView($session) ){
      my @sqlParams = ();
      my @likableItemPositions = ();
      my $searchParam = undef;      
      my $search = $session->form->param('sSearch');
      if ( $search ){
         $searchParam = q|and users.username like ?|;
         push(@likableItemPositions, scalar( @sqlParams ) );
         push(@sqlParams, $search);
      }
      
      my $limitParam = undef;      
      my $limit = $session->form->param('iDisplayLength');
      if ( $limit ){
         $limitParam = qq| limit ?|;
         push(@sqlParams, $limit);
      }
      
      my $sqlCommand = qq|select users.username,users.userId,userSession.sessionId,userSession.expires,
            userSession.lastPageView,userSession.lastIP from users,userSession where users.userId=userSession.userId
            and users.userId<>1 $searchParam order by users.username,userSession.lastPageView desc $limitParam|;
            
      my $sth = $session->db->prepare( $sqlCommand );
      # Find the items that are going to require the %{search_term}% special characters 
      my %like_params = map { $_ => 1 } @likableItemPositions;
      if ( @sqlParams ){
         for( my $index = 0; $index <= $#sqlParams; $index++ ){
            my $position = $index + 1;
            my $value = $sqlParams[ $index ];
            # Like values need the special characters
            if ( %like_params && $like_params{ $index } ){
               $value .= '%';
               $value = '%' . $value;
            }
            $sth->bind_param( $position, $value );
         }   
      }  
      $sth->execute();

      my $output = [];
      while ( my $data = $sth->hashRef ) {
         push(@{ $output },{
              expires      => $session->datetime->epochToHuman($data->{expires}),
              lastPageView => $session->datetime->epochToHuman($data->{lastPageView}),
              lastIP       => $data->{lastIP},
              username     => $data->{username},
              userId       => $data->{userId}, 
              sessionId    => $data->{sessionId}
         });
      }
      my $rowCount = @{ $output };
      
      $webParams->{iTotalRecords} = $rowCount;
      $webParams->{iTotalDisplayRecords} = $limit;
      $webParams->{data} = $output;
   
   }else{
      $session->response->status(403);   
      $webParams->{header} = $i18n->get(35);
      $webParams->{error}  = $i18n->get(36);
      
   }
   
   return to_json $webParams;
}

1;

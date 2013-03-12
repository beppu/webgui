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
use WebGUI::International;
use JSON;
use Moose;

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
   my $rest = WebGUI::Session::Rest->new( session => $session );
   # should not delete our own session
   if ( $session->form->process("sid") eq $session->getId ){
      return $rest->notModified( $i18n->get(108) );

   # delete the sessions
   }elsif ( canView($session) ){ # && $session->request->method eq 'DELETE'
      my @sessionIds = split(',', $session->form->process("sid") );
      foreach my $sessionId ( @sessionIds ){ # NOT the right way to do it but for now it works
         $session->db->deleteRow("userSession","sessionId", $sessionId);
         $session->db->deleteRow("userSessionScratch","sessionId", $sessionId);
         
      }
	   return $rest->response; # json success

   # Permission denied
   }else{
      return $rest->forbidden( $i18n->get(36) );
      
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
   my $rest = WebGUI::Session::Rest->new( session => $session );
   my $webParams = $session->request->parameters->mixed;
   if ( canView($session) ){
      my @sqlParams = ();
      my @likableItemPositions = ();
      my $searchParam = "";      
      my $search = $session->form->param('sSearch');
      if ( $search ){
         $searchParam = q|and users.username like ?|;
         push(@likableItemPositions, scalar( @sqlParams ) );
         push(@sqlParams, $search);
      }
      
      my $limitParam = "";
      my $start = $session->form->param('iDisplayStart');
      my $length = $session->form->param('iDisplayLength');
      if ( $length ){
         $limitParam = qq| LIMIT ?, ?|;
         push(@sqlParams, $start);         
         push(@sqlParams, $length);
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
               $value = '%' . $value . '%';
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
      my $rowCount = $sth->rows;
      
      $sqlCommand = qq|select count(*) from users,userSession where users.userId=userSession.userId and users.userId<>1|;      
      
      $webParams->{iTotalRecords} = $session->db->quickScalar( $sqlCommand ); # Kind of overkill but required for pagination.  total records in database
      $webParams->{iTotalDisplayRecords} = $search ? $rowCount : $webParams->{iTotalRecords}; #Total records, after filtering or same as total records if not filtering
      $webParams->{data} = $output;
      $rest->data( $webParams );
      return $rest->response;
      
   }else{
      return $rest->forbidden( $i18n->get(36) );      
      
   }
   
}

1;

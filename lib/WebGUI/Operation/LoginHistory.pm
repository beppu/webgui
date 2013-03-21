package WebGUI::Operation::LoginHistory;

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
use WebGUI::Session::Rest;

=head1 NAME

Package WebGUI::Operation::LoginHistory

=cut

#----------------------------------------------------------------------------

=head2 canView ( session [, user] )

Returns true if the user can administrate this operation. user defaults to 
the current user.

=cut

sub canView {
    my $session = shift;
    my $user    = shift || $session->user;
    return $user->isInGroup( $session->setting->get("groupIdAdminLoginHistory") );
}

#-------------------------------------------------------------------

=head2 www_viewLoginHistory ( )

Display the login history for all users by when they logged in.
The login history is a table of username, userId, status, login date,
IP address they logged in from and what browser (really userAgent)
they used.

=cut

sub www_viewLoginHistory {
	my $session = shift;
	my $i18n = WebGUI::International->new($session);
	my $rest = WebGUI::Session::Rest->new( session => $session );
   my $webParams = $session->request->parameters->mixed;
	if ( canView($session) ) {		
      my @sqlParams = ();
      my @likableItemPositions = ();
      my $searchParam = "";      
      my $search = $session->form->param('sSearch');
      if ( $search and $search =~ m/\S/ ){ # don't search unless we have something to search for, i.e. alpha characters
         $searchParam = q|and username like ?|;
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

      my $sqlCommand = qq|select * from users,userLoginLog where users.userId=userLoginLog.userId $searchParam order by userLoginLog.timeStamp desc $limitParam|;
            
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
         my $lastPageViewed = 'Active';
         my $sessionLength  = 'Active';
         if ( $data->{lastPageViewed} ) {
            if ( $data->{lastPageViewed} != $data->{timeStamp} ) {
               $lastPageViewed = $session->datetime->epochToHuman( $data->{lastPageViewed},"%H:%n%p %M/%D/%y" );
               my ($interval, $units) = $session->datetime->secondsToInterval( $data->{lastPageViewed} - $data->{timeStamp} );
               $sessionLength = qq|$interval $units|;
            }
            
         } else {
            $lastPageViewed = '';
            $sessionLength  = '';
            
         }        
        
         push(@{ $output },{
            username       => $data->{userId} eq '0' ? $i18n->get('unknown user') : $data->{username} . ' ' . $data->{userId},
            status         => $data->{status},
            timeStamp      => $session->datetime->epochToHuman( $data->{timeStamp} ),
            ipAddress      => $data->{ipAddress},            
            userAgent      => $data->{userAgent},
            sessionId      => $data->{sessionId},            
            lastPageViewed => $lastPageViewed,
            sessionLength  => $sessionLength
         });
      }
      my $rowCount = @{ $output };
      
      $sqlCommand = qq|select count(*) from users,userLoginLog where users.userId=userLoginLog.userId|;      
      
      $webParams->{iTotalRecords} = $session->db->quickScalar( $sqlCommand ); # Kind of overkill but required for pagination.  total records in database
      $webParams->{iTotalDisplayRecords} = $webParams->{iTotalRecords}; #Total records, after filtering
      $webParams->{data} = $output;
      return $rest->response( $webParams );
      
	}else {
      return $rest->forbidden( { message => $i18n->get(36) } );
		
   }
}

1;

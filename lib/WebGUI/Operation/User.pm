package WebGUI::Operation::User;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict qw(vars subs);
use Tie::IxHash;
use WebGUI::AdminConsole;
use WebGUI::Group;
use WebGUI::Form;
use WebGUI::Form::DynamicField;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Operation::Auth;
use WebGUI::Paginator;
use WebGUI::Session::Rest;
use WebGUI::SQL;
use WebGUI::User;
use JSON;
use XML::Simple;
use Net::CIDR::Lite;

=head1 NAME

Package WebGUI::Operation::User

=head1 DESCRIPTION

Operation for creating, deleting, editing and many other user related functions.

=cut

#----------------------------------------------------------------------------

=head2 canAdd ( session [, user] )

Returns true if the user is allowed to add other users. user defaults to the
current user.

=cut

sub canAdd {
    my $session     = shift;
    my $user        = shift || $session->user;
    return $user->isInGroup( $session->setting->get("groupIdAdminUserAdd") )
        || canEdit($session, $user)
        ;
}

#----------------------------------------------------------------------------

=head2 canEdit ( session [, user] )

Returns true if the user is allowed to do everything in this module. user 
defaults to the current user.

=cut

sub canEdit {
    my $session     = shift;
    my $user        = shift || $session->user;
    return $user->isInGroup( $session->setting->get("groupIdAdminUser") );
}

#----------------------------------------------------------------------------

=head2 canUseService ( session )

Returns true if the current session is allowed to use the web service, i.e.
is in one of the configured CIDR subnets in the config file.

=cut

sub canUseService {
    my ( $session ) = @_;
    my $subnets = $session->config->get('serviceSubnets');
    return 1 if !$subnets || !@{$subnets};
    return 1 if Net::CIDR::Lite->new(@$subnets)->find($session->request->address);
    return 0; # Don't go away mad, just go away
}

#----------------------------------------------------------------------------

=head2 canView ( session [, user] )

Returns true if the user is allowed to see this module. user defaults to the
current user.

=cut

sub canView {
    my $session     = shift;
    my $user        = shift || $session->user;
    return canAdd($session, $user);
}

#-------------------------------------------------------------------

=head2 createServiceResponse ( format, data ) 

Create a string with the correct C<format> from the given C<data>.

Possible formats are "json" and "xml".

=cut

sub createServiceResponse {
    my ( $format, $data ) = @_;
    
    if ( lc $format eq "xml" ) {
        return XML::Simple::XMLout($data, NoAttr => 1, RootName => "response" );
    }
    else {
        return JSON->new->encode($data);
    }
}

#-------------------------------------------------------------------

=head2 www_confirmUserEmail ( )

Process links clicked from mails sent out by the WaitForUserConfmration
workflow activity.

=cut

sub www_confirmUserEmail {
    my $session    = shift;
    my $f          = $session->form;
    my $instanceId = $f->get('instanceId');
    my $token      = $f->get('token');
    my $actId      = $f->get('activityId');
    my $activity   = WebGUI::Workflow::Activity->new($session, $actId)
        or die;
    my $instance   = WebGUI::Workflow::Instance->new($session, $instanceId)
        or die;
    if ($activity->confirm($instance, $token)) {
        my $msg  = $activity->get('okMessage');
        unless ($msg) {
            my $i18n = WebGUI::International->new($session, 'WebGUI');
            $msg = $i18n->get('ok');
        }
        return $session->style->userStyle($msg);
    }
    else {
        return $session->privilege->noAccess;
    }
}

#-------------------------------------------------------------------

=head2 www_deleteUsers ( )

Delete a user using a web service.

=cut

sub www_deleteUsers {
    my $session = shift;
    
	 my $i18n = WebGUI::International->new($session);
    my $rest = WebGUI::Session::Rest->new( session => $session );

    my $output = $session->request->parameters->mixed;
    # If the user is only allowed to add users, send them right there.
	 unless ( canEdit($session) && canUseService($session) ){
		 return $rest->forbidden({ message => $i18n->get(36) });

	 }

    # Verify data
    my @userIds = split(',', $session->form->get('ids'));

    return $rest->response({ message => "userid" })
       unless @userIds;
    
    foreach my $userId ( @userIds ){
       # make sure we don't remove essential users
       if ( $userId eq "1" || $userId eq "3" ) {
          return $rest->vitalComponent()

       }elsif ( ! WebGUI::User->validUserId( $session, $userId ) ) {
          return $rest->response({ message => "userid" });

       }else{
          ### Delete user
          my $user = WebGUI::User->new( $session, $userId );
          $user->delete;
       }

    }

    return $rest->response({});
}

#-------------------------------------------------------------------

=head2 www_becomeUser ( )

Allows an administrator to assume another user.

=cut

sub www_becomeUser {
	my $session = shift;
	return $session->privilege->adminOnly() unless canEdit($session) && $session->form->validToken;
	return undef unless WebGUI::User->validUserId($session, $session->form->process("uid"));
	$session->end();
	$session->user({userId=>$session->form->process("uid")});
	return "";
}

#-------------------------------------------------------------------

=head2 www_editUser ( )

Provides values for editing a user, or adding a new user.

=cut

sub www_editUser {
	my $session = shift;
	my $error = shift;
   my $uid = shift || $session->form->process("uid");

   my $i18n = WebGUI::International->new($session, "WebGUI");
   my $rest = WebGUI::Session::Rest->new(session => $session);

	return $rest->unauthorized({ message => 'unauthorized' }) # ::TODO:: i18n
      unless canAdd( $session );
   if ( $uid eq 'new' ){
      $uid = '';#Setting uid to '' when uid is 'new' so visitor defaults prefill field for new user and a NEW user is NOT created
   }
	my $user = WebGUI::User->new($session, $uid); 
	my $username = ($user->isVisitor && $uid ne "1") ? '' : $user->username;

   my $hiddenToken = WebGUI::Form::CsrfToken->new($session)->toHtml;
   my $output = {
      token => $hiddenToken,
      uid   => $uid,

      karma => {
         class       => 'account',
			label       => $i18n->get('84 description'),
			value       => $user->karma,
			description => ""			  
		},

      dateCreated => {
         class       => 'account',
			label       => $i18n->get(453),
			value       => $session->datetime->epochToHuman($user->dateCreated,"%z"),
			description => ""			  
		},

      lastUpdated => {
         class       => 'account',
			label       => $i18n->get(454),
			value       => $session->datetime->epochToHuman($user->lastUpdated,"%z"),
			description => ""			  
		},

      username => {
         class       => 'account',
			label       => $i18n->get(50),
			value       => $username,
			description => ""			  
		},

      status => {
         id      => 'status',
         class   => 'account',
         name    => 'status',
         label   => $i18n->get(816),
         type    => 'select',
         options => [
            { value =>'Active',         label => $i18n->get(817), selected => $user->status eq 'Active'         ? 'selected' : undef },
            { value =>'Deactivated',    label => $i18n->get(818), selected => $user->status eq 'Deactivated'    ? 'selected' : undef },
            { value =>'Selfdestructed', label => $i18n->get(819), selected => $user->status eq 'Selfdestructed' ? 'selected' : undef }
         ]
      }
   };

   # Get the default WebGUI auth method
   my $authInstance = WebGUI::Operation::Auth::getInstance($session, 'WebGUI', $uid);
   $output->{authMethod} = {
      label   => 'WebGUI',
      options => $authInstance->editUserFields()
   };
   # Set the auth methods
   my $authMethodOptions = [];

   foreach my $authMethod ( @{ $session->config->get("authMethods") } ){
      push(@{ $authMethodOptions }, {
         value    => $authMethod,
         label    => $authMethod,
         selected => $user->authMethod eq $authMethod ? 'selected' : ''
      });
   }
	$output->{authMethods} = {
       id      => 'authMethod',
       class   => 'authMethod',
       name    => 'authMethod',
       label   => $i18n->get(164),
       type    => 'select',
       options => $authMethodOptions 
   };

   # Profile fields
   my $userProfileFields = $user->get();
   my $profile = [];
	foreach my $category ( @{ WebGUI::ProfileCategory->getCategories($session) } ) {
      my $fields = [];
		foreach my $field ( @{ $category->getFields } ){
			next if $field->getId =~ /contentPositions/;
         my $defaultValue = $user->get( $field->getId ) || $userProfileFields->{ $field->getId };# just in case we are editing an existing user or get default value

         # get the field type
         my $fieldOptions = [];
         my $optionsHash = undef;
         my $selectedItem = undef;
         my $type = $field->formProperties->{fieldType};
         if ( lc($type) eq 'selectbox' ){
            # If we have any options split into a usable set for the Javascript API
            $optionsHash = $field->formProperties->{options};
            $selectedItem = 'selected';
            $type = 'select';
            
         }elsif ( lc($type) eq 'yesno' || lc($type) eq 'radiolist' ){ # unfortunately I found "yesNo" and "YesNo" values
            my $yesNo = WebGUI::Form::YesNo->new( $session );
            $optionsHash = $yesNo->getOptions;
            $selectedItem = 'checked';
            $type = 'radio'; 

         }
         # If we do not have a default set one from the options hash if we indeed have an options hash
         if ( ! $defaultValue && $optionsHash ){
            my @keys = keys( %{ $optionsHash } );
            $defaultValue = shift( @keys );
         }
#
#
#if ( $field->getId eq 'allowPrivateMessages' ){
#   use Data::Dumper;
#   $session->log->error( $field->getId . " = ( $defaultValue ) Duper: " . Dumper $optionsHash );
#}
#
#
#
#

         foreach my $key ( keys %{ $optionsHash } ){
            push(@{ $fieldOptions }, {
               value    => $key,
               label    => $optionsHash->{ $key },
               selected => $defaultValue eq $key ? $selectedItem : undef
            });
         }

			push(@{ $fields }, {
            id       => $field->getId,
            class    => 'profile',
            name     => $field->getId,
            label    => $field->getLabel . ($field->isRequired ? "*" : ''),
            reserved => $field->isReservedFieldName,
            extras   => $field->getExtras,
            viewable => $field->isViewable,
            value    => $defaultValue,
            options  => $fieldOptions,
            type     => $type,
            required => $field->isRequired       
         });
		}

      push( @{ $profile }, {
         name   => $category->getLabel, 
         label  => $category->getLabel,
         values => $fields

      });

	}
   $output->{profile} = $profile;

   return $rest->response( $output );

}

#-------------------------------------------------------------------

=head2 www_editUserSave ( )

Process the editUser form data.  Returns adminOnly unless the user has privileges
to add/edit users and the submitted form passes the validToken check.

=cut

sub www_editUserSave {
	my $session = shift;

	my $i18n = WebGUI::International->new($session);
   my $rest = WebGUI::Session::Rest->new(session => $session);
	my $postedUserId = $session->form->process("uid") || 'new'; #userId posted from www_editUser form
	my $isAdmin = canEdit( $session );

	my $isSecondary;
	unless ( $isAdmin ) {
		$isSecondary = (canAdd($session) && $postedUserId eq 'new');

	}

	return $rest->unauthorized({ message => "Admin Only" }) # ::TODO:: i18n 
      unless ( ( $isAdmin || $isSecondary ) && $session->form->validToken );

	my ($existingUserId) = $session->db->quickArray("select userId from users where username= ?", [ $session->form->process("username") ]);
	my $error;
	my $actualUserId;  #userId returned from the user object
   # Check to see if
	# 1) the userId associated with the posted username matches the posted userId (we're editing an account)
	# or that the userId is new and the username selected is unique (creating new account)
	# or that the username passed in isn't assigned a userId (changing a username)
	#
	# Also verify that the posted username is not blank (we need a username)
	#

	my $postedUsername = $session->form->process("username");
	$postedUsername = WebGUI::HTML::filter($postedUsername, "all");

   if (($existingUserId eq $postedUserId || ($postedUserId eq "new" && !$existingUserId) || $existingUserId eq '') && $postedUsername ne ''){
      # Create a user object with the id passed in.  If the Id is 'new', the new method will return a new user,
      # otherwise return the existing users properties
    	my $user = WebGUI::User->new($session,$postedUserId);
	  	$actualUserId = $user->userId;

		# Update the user properties with passed in values.  These methods will save changes to the db.
	  	$user->username($postedUsername);
	  	$user->authMethod($session->form->process("authMethod"));
	  	$user->status($session->form->process("status"));

      # Loop through all of this users authentication methods
      foreach (@{$session->config->get("authMethods")}) {
         # Instantiate each auth object and call it's save method.  These methods are responsible for
         # updating authentication information with values supplied by the www_editUser form.
         my $authInstance = WebGUI::Operation::Auth::getInstance($session, $_, $actualUserId);
         $authInstance->editUserFormSave();
      }
       		
      # Loop through all profile fields, and update them with new values.
      my $address          = {};
      my $address_mappings = WebGUI::Shop::AddressBook->getProfileAddressMappings;
      foreach my $field (@{WebGUI::ProfileField->getFields($session)}) {
			next if $field->getId =~ /contentPositions/;
         my $field_value = $field->formProcess($user);
			$user->update({ $field->getId => $field_value} );

         #set the shop address fields
         my $address_key          = $address_mappings->{$field->getId};
         $address->{$address_key} = $field_value if ($address_key);
		}

      #Update or create and update the shop address
      if ( keys %$address ) {
         $address->{'isProfile'} = 1;

         #Get the address book for the user (one is created if it does not exist)
         my $addressBook     = WebGUI::Shop::AddressBook->newByUserId($session, $actualUserId,);
         my $profileAddress = eval { $addressBook->getProfileAddress() };

         my $e;
         if( $e = WebGUI::Error->caught('WebGUI::Error::ObjectNotFound') ){
            #Get home address only mappings to avoid creating addresses with just firstName, lastName, email
            my %home_address_map = %{$address_mappings};
            delete $home_address_map{qw/firstName lastName email/};
            #Add the profile address for the user if there are homeAddress fields
            if( grep { $address->{$_} } values %home_address_map ){
                $address->{label} = "Profile Address";
                my $new_address = $addressBook->addAddress($address);
                #Set this as the default address if one doesn't already exist
                my $defaultAddress = eval{ $addressBook->getDefaultAddress };
                if( WebGUI::Error->caught('WebGUI::Error::ObjectNotFound') ){
                   $addressBook->update( { defaultAddressId => $new_address->getId } );

                }else{
                   $session->log->warn("The default address exists, and it should not.");
                }
            }

         }elsif ($e = WebGUI::Error->caught) {
            #Bad stuff happened - log an error but don't fail since this isn't a vital function
             $session->log->error( q{Could not update Shop Profile Address for user } . $user->username.q{ : }.$e->error );

         }else{
            #Update the profile address for the user
            $profileAddress->update($address);
         }
      }
		
		# Update group assignements
		my @groups = $session->form->group("groupsToAdd");
		$user->addToGroups(\@groups);
		@groups = $session->form->group("groupsToDelete");
		$user->deleteFromGroups(\@groups);
	
      # trigger workflows	
      if ($postedUserId eq "new") {
	      if ($session->setting->get("runOnAdminCreateUser")) {
		      WebGUI::Workflow::Instance->create($session, {
		           workflowId=>$session->setting->get("runOnAdminCreateUser"),
			        methodName=>"new",
			        className=>"WebGUI::User",
			        parameters=>$user->userId,
			        priority=>1
			   })->start;
	      }

      }else{
         if ($session->setting->get("runOnAdminUpdateUser")) {
		        WebGUI::Workflow::Instance->create($session, {
			        workflowId=>$session->setting->get("runOnAdminUpdateUser"),
			        methodName=>"new",
			        className=>"WebGUI::User",
			        parameters=>$user->userId,
			        priority=>1
		        })->start;
         }
      }
      return $rest->response({ id => $user->userId });

	# Display an error telling them the username they are trying to use is not available and suggest alternatives	
   }else{
      $error = sprintf($i18n->get(77), $postedUsername, $postedUsername, $postedUsername, $session->datetime->epochToHuman(time(),"%y"));
      return $rest->response({ message => $error });

	}

#	if ( $isSecondary ){
#		return _submenu($session,{workarea => $i18n->get(978)});
#
#	# Display updated user information
#	} else {
#		return www_editUser($session,$error,$actualUserId);
#	}
}

#-------------------------------------------------------------------

=head2 www_editUserKarma ( )

Provides a form for directly editing the karma for a user.  Returns adminOnly
unless the current user can manage users.

=cut

sub www_editUserKarma {
	my $session = shift;
	return $session->privilege->adminOnly() unless canEdit($session);
        my ($output, $f, $a, %user, %data, $method, $values, $category, $label, $default, $previousCategory);
	my $i18n = WebGUI::International->new($session);
        $f = WebGUI::HTMLForm->new($session);
	$f->submit;
        $f->hidden(
		-name => "op",
		-value => "editUserKarmaSave",
        );
        $f->hidden(
		-name => "uid",
		-value => $session->form->process("uid"),
        );
	$f->integer(
		-name => "amount",
		-label => $i18n->get(556),
		-hoverHelp => $i18n->get('556 description'),
	);
	$f->text(
		-name => "description",
		-label => $i18n->get(557),
		-hoverHelp => $i18n->get('557 description'),
	);
   $f->submit;
   $output .= $f->print;
	my $submenu = _submenu(
     $session,
     { workarea => $output,
          title => 558 }
   );  
   return $submenu;
}

#-------------------------------------------------------------------

=head2 www_editUserKarmaSave ( )

Processes the form submitted  by www_editUserKarma.  Returns adminOnly
unless the current user can manage users and the submitted from passes
the validToken check.

=cut

sub www_editUserKarmaSave {
	my $session = shift;
	return $session->privilege->adminOnly() unless canEdit($session) && $session->form->validToken;
   my $user = WebGUI::User->new($session,$session->form->process("uid"));
   $user->karma($session->form->process("amount"),$session->user->username." (".$session->user->userId.")",$session->form->process("description"));
   return www_editUser($session);

}

#-------------------------------------------------------------------

=head2 www_listUsers ( )

Provides a paginated list of all users, and controls for adding a new user.  If the
current user is only allowed to add users, then it sends them directly to www_editUser.
If the current user is not allowed to edit or create users, it returns adminOnly.

=cut

sub www_listUsers {
	my $session = shift;

	my $i18n = WebGUI::International->new($session);
   my $rest = WebGUI::Session::Rest->new( session => $session );

   my $output = $session->request->parameters->mixed;
   # If the user is only allowed to add users, send them right there.
	unless ( canEdit($session) ) {
		if ( canAdd($session) ) {
			return $rest->response({ op => "new" });
		}
      else {
		   return $rest->forbidden({ message => $i18n->get(36) });
      }
	}

	my ($userCount) = $session->db->quickArray("select count(*) from users");
   if ( $userCount > 250 ){ # This should really be pulled from the config file it could be config->{highUserCount} || 250
      $output->{alertMessage} = $i18n->get('high user count');
   }
   $output->{iTotalRecords} = $userCount; # Kind of overkill but required for pagination.  total records in database 

	my $status = {
		Active		   => $i18n->get(817),
		Deactivated	   => $i18n->get(818),
		Selfdestructed	=> $i18n->get(819)
	};
   $output->{statusCodes} = $status;

   my $user_loginlog = $session->db->prepare(
        q{
            select   status, timeStamp, lastPageViewed, sessionId
            from     userLoginLog
            where    userId = ?
            order by timeStamp desc
            limit    1
        },
    );
    my $last_page_view = $session->db->prepare(
        q{
            select lastPageView
            from   userSession
            where  sessionId = ?
        },
    );
    my $total_time = $session->db->prepare(
        q{
            select sum(lastPageViewed - timeStamp) 
            from   userLoginLog 
            where  userId = ?
        },
    );

   # If the we need to limit the list by user search
   my $search = $session->form->process('sSearch');
   if ( $search =~ m/\S/ ){
	   $session->scratch->set("userSearchKeyword", $search);
      $session->scratch->set("userSearchModifier", "contains");

   }else{
	   $session->scratch->delete('userSearchKeyword');
	   $session->scratch->delete('userSearchModifier');

   }

	my $sth = doUserSearch( $session, "listUsers" );# no paginator, however we may have millions of users
   my $limit = $session->form->process("limit");
   my $users = [];
	while ( my $data = $sth->fetchrow_hashref ){
      my $user = {
         id       => $data->{userId},
         status   => $status->{ $data->{status} },
         username => $data->{username},
         email    => $data->{email},
         created  => $session->datetime->epochToHuman($data->{dateCreated},"%z"),
         updated  => $session->datetime->epochToHuman($data->{lastUpdated},"%z"),
      };

      # Find out the last time this user logged in
      $user_loginlog->execute([$data->{userId}]);
      my ( $status, $lastLogin, $lastView, $lastSession ) = $user_loginlog->fetchrow_array;

      # Find out the last time this user accessed the site
      $last_page_view->execute([$lastSession]);
      my ($trueLastView) = $last_page_view->fetchrow_array();

      # format last page view, preferring session recorded view time
      $lastView   = $trueLastView || $lastView;
      $lastView &&= $session->datetime->epochToHuman($lastView);

      $lastLogin &&= $session->datetime->epochToHuman($lastLogin);

      $total_time->execute([$data->{userId}]);
      my ($totalTime) = $total_time->fetchrow_array();

      if ($totalTime) {
         my ($interval, $units) = $session->datetime->secondsToInterval($totalTime);
         $totalTime = "$interval $units";
      }

      $user->{metrics} = {
          lastLogin => $lastLogin,
          status    => $status,
          lastView  => $lastView,
          totalTime => $totalTime
      };

      push(@{ $users }, $user); 
      # Just in case
      if ( $limit ){
         $limit--;
         last if $limit == 0;
      }
	}
   $output->{users} = $users;
   $output->{iTotalDisplayRecords} = $sth->rows; #Total records, after filtering or same as total records if not filtering

   $user_loginlog->finish;
   $last_page_view->finish;
   $total_time->finish;

   return $rest->response( $output ); 
}

#-------------------------------------------------------------------

=head2 www_listUserGroups ( )

Provides a paginated list of all groups for this user.

=cut

sub www_listUserGroups {
	my $session = shift;

	my $i18n = WebGUI::International->new($session);
   my $rest = WebGUI::Session::Rest->new( session => $session );
   my $uid  = $session->form->param('uid');

   return $rest->forbidden( { message => $i18n->get(36) } )
      unless canView( $session, $session->user );
   
   my $output = $session->request->parameters->mixed;

   my $sqlCommand = "select count(*) from groups where isEditable=1";
   $output->{iTotalRecords} = $session->db->quickScalar( $sqlCommand ); # Kind of overkill but required for pagination.  total records in database
   
   $sqlCommand = q|select * from groups where isEditable=1 |;
   my @sqlParams = undef;
   # Only list the user groups if the user exists
   if ( $uid eq 'new' || $uid !~ m/\S/ ){
      # we are using a group that will never exist so we can get all groups since this is a new user
      @sqlParams = ('NEWUSER'); 

   }else{
      my $user = WebGUI::User->new( $session, $uid );
      my $userGroupsIds = $user->getGroups();
      @sqlParams = @{ $userGroupsIds };

   }

   my $parameterCount = @sqlParams;
   my $parameterPlaceholders = join(",",split(" ",("? " x $parameterCount)));
   my $dataParam = undef;
   # Groups user does not belongs to
   if ( $session->form->param('not') ){
      if ( $parameterCount > 0 ){
         $sqlCommand .= qq| and groupId not in ($parameterPlaceholders) |;
      } 
      $dataParam = 'availableGroups';

   # Grous the user belongs to
   }else{
      if ( $parameterCount > 0 ){
         $sqlCommand .= qq| and groupId in ($parameterPlaceholders) |;
      }
      $dataParam = 'groups';

   }
 
   my $search = $session->form->param('sSearch');
   if ( $search && $search =~ m/\S/ ){
      $sqlCommand .= qq| and groupName like ? |;
      push(@sqlParams, '%' . $search . '%');

   }

   my $start  = $session->form->param('iDisplayStart');
   my $length = $session->form->param('iDisplayLength');
   if ( $start && $length ){
      $sqlCommand .= qq| LIMIT ?, ? |;
      push(@sqlParams, $start, $length);         
   }

   my $rowCount = 0;
   my $groups = [];
   my $sth = $session->db->read($sqlCommand, [@sqlParams]);
   while( my $row = $sth->fetchrow_hashref ){
      push( @{ $groups }, {
         groupName   => $row->{groupName},
         groupId     => $row->{groupId},
         description => $row->{description}
      });
      $rowCount++;
   }

   $output->{iTotalDisplayRecords} = $rowCount > 0 ? $rowCount : $output->{iTotalRecords};

   $output->{ $dataParam } = {
      id      => 'userGroups',
      class   => 'userGroups',
      name    => 'userGroups',
      label   => $i18n->get("groups to delete"),
      type    => 'select',
      options => $groups

   };

   return $rest->response( $output ); 

}

1;
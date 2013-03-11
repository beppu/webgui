package WebGUI::Operation::Group;

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
use WebGUI::Group;
use WebGUI::Form;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Mail::Send;
use WebGUI::Operation::User;
use WebGUI::Paginator;
use WebGUI::Session::Rest;
use WebGUI::SQL;
use Tie::IxHash;

#----------------------------------------------------------------------------
sub _submenu {
	my $session = shift;
        my $workarea = shift;
        my $title = shift;
	my $i18n = WebGUI::International->new($session);
        $title = $i18n->get($title) if ($title);
        my $ac = WebGUI::AdminConsole->new($session,"groups");
	if (canEditAll($session)) {
	        $ac->addSubmenuItem($session->url->page('op=editGroup;gid=new'), $i18n->get(90));
	}
	if (canView($session)) {
        	unless ($session->form->process("op") eq "listGroups" 
			|| $session->form->process("gid") eq "new" 
			|| $session->form->process("op") eq "deleteGroupConfirm") {
        	        $ac->addSubmenuItem($session->url->page("op=editGroup;gid=".$session->form->process("gid")), $i18n->get(753));
                	$ac->addSubmenuItem($session->url->page("op=manageUsersInGroup;gid=".$session->form->process("gid")), $i18n->get(754));
	                $ac->addSubmenuItem($session->url->page("op=manageGroupsInGroup;gid=".$session->form->process("gid")), $i18n->get(807));
        	        $ac->addSubmenuItem($session->url->page("op=emailGroup;gid=".$session->form->process("gid")), $i18n->get(808));
                	$ac->addConfirmedSubmenuItem($session->url->page("op=deleteGroup;gid=".$session->form->process("gid")), $i18n->get(806), $i18n->get(86));
	        }
        	$ac->addSubmenuItem($session->url->page("op=listGroups"), $i18n->get(756));
	}
    return $ac->render($workarea, $title);
}


#----------------------------------------------------------------------------

=head2 canEditAll ( session [, user] )

Returns true if the user is allowed to edit all groups. user defaults to the
current user.

=cut

sub canEditAll {
    my $session     = shift;
    my $user        = shift || $session->user;
    return $user->isInGroup( $session->setting->get("groupIdAdminGroup") );
}

#----------------------------------------------------------------------------

=head2 canEditGroup ( session, group [, user] )

Returns true if the user can edit the specified group. user defaults to the
current user.

=cut

sub canEditGroup {
    my $session     = shift;
    my $groupId     = shift;
    my $user        = shift || $session->user;
    
    return 1 if canEditAll($session, $user);

	my $group = WebGUI::Group->new($session,$groupId);
    return
        unless $group;
    return $user->isInGroup( $session->setting->get("groupIdAdminGroupAdmin") )  
        && $group->userIsAdmin( $user->userId )
        ;
}

#----------------------------------------------------------------------------

=head2 canView ( session [, user] )

Returns true if the user is allowed to use this control in any capacity. user
defaults to the current user.

=cut

sub canView {
    my $session     = shift;
    my $user        = shift || $session->user;
    
    return canEditAll($session, $user)
        || $user->isInGroup( $session->setting->get("groupIdAdminGroupAdmin") )
        ;
}

#-------------------------------------------------------------------

=head2 doGroupSearch ($session, $op, $returnPaginator, $groupFilter)

Do a search of group names and descriptions for the keyword set in the
form variable C<groupSearchKeyword>.

=head3 $session

A WebGUI::Session object

=head3 $op

A URL query fragment to use with the paginator.

=head3 $returnPaginator

If set to true, then this function will return a WebGUI::Paginator
object.

=head3 $groupFilter

An array reference of groupIds to exclude from the search.

=cut

sub doGroupSearch {
	my $session         = shift;
	my $op              = shift;
        my $returnPaginator = shift;
        my $groupFilter     = shift || [];
        push(@{$groupFilter},0);
        my $keyword = $session->scratch->get("groupSearchKeyword");
        if ($session->scratch->get("groupSearchModifier") eq "startsWith") {
                $keyword .= "%";
        } elsif ($session->scratch->get("groupSearchModifier") eq "contains") {
                $keyword = "%".$keyword."%";
        } else {
                $keyword = "%".$keyword;
        }
	$keyword = $session->db->quote($keyword);
	my $sql = "select groupId,groupName,description from groups where isEditable=1 and (groupName like $keyword or description like $keyword) 
		and groupId not in (".$session->db->quoteAndJoin($groupFilter).") order by groupName";
	if ($returnPaginator) {
                my $p = WebGUI::Paginator->new($session,$session->url->page($op));
                $p->setDataByQuery($sql);
                return $p;
        } else {
                my $sth = $session->db->read($sql);
                return $sth;
        }
}


#-------------------------------------------------------------------

=head2 getGroupSearchForm ($session, $op, $params)

Build and render a form for doing group searching.

=head3 $session

A WebGUI::Session object

=head3 $op

The operation that this form should call when submitted.

=head3 $params

A hashref of hidden form parameters and values to add to the form.


=cut

sub getGroupSearchForm {
	my $session = shift;
	my $op = shift;
	my $params = shift;
	my $keyword = $session->form->process("keyword");
	if (defined $keyword) {
		$session->scratch->set("groupSearchKeyword", $keyword);
	}
	my $modifier = $session->form->process("modifier");
	if (defined $modifier) {
		$session->scratch->set("groupSearchModifier", $modifier);
	}
	my $output = '<div align="center">';
	my $i18n = WebGUI::International->new($session);
	my $f = WebGUI::HTMLForm->new($session, method => 'GET', );
	foreach my $key (keys %{$params}) {
                $f->hidden(
                        -name=>$key,
                        -value=>$params->{$key}
                        );
        }  
        $f->hidden(
		-name => "op",
		-value => $op
	);
        $f->hidden(
                -name=>"doit",
                -value=>1
                );
        $f->selectBox(
                -name=>"modifier",
                -value=>($session->scratch->get("groupSearchModifier") || "contains" ),
                -options=>{
                        startsWith=>$i18n->get("starts with"),
                        contains=>$i18n->get("contains"),
                        endsWith=>$i18n->get("ends with")
                        }
                );
        $f->text(
                -name=>"keyword",
                -value=>$session->scratch->get("groupSearchKeyword"),
                -size=>15
                );
        $f->submit(value=>$i18n->get(170));
        $output .= $f->print;
        $output .= '</div>';
	return $output;
}


#-------------------------------------------------------------------

=head2 walkGroups ($session, $parentId, $indent)

Recursively find all groups which are members of this group.  Each
group is rendered with an indent, a delete from grouping icon and
an edit icon.

Returns the HTML.

=head3 $session

A WebGUI::Session object

=head3 $parentId

The GUID of the group to display the children of.

=head3 $indent

A snippet of HTML to indent a group, to show hierarchy.

=cut

sub walkGroups {
	my $session = shift;
        my $parentId = shift;
        my $indent = shift;
	my $output;
        my $sth = $session->db->read("select groups.groupId, groups.groupName from groupGroupings left join groups on groups.groupId=groupGroupings.groupId where groupGroupings.inGroup=".$session->db->quote($parentId));
        while (my ($id, $name) = $sth->array) {
		$output .= $indent
			.$session->icon->delete('op=deleteGroupGrouping;gid='.$parentId.';delete='.$id)
			.$session->icon->edit('op=editGroup;gid='.$id)
			.' '.$name.'<br />';
                $output .= walkGroups($session, $id,$indent."&nbsp; &nbsp; ");
        }
        $sth->finish;
	return $output;
}

#-------------------------------------------------------------------

=head2 www_addGroupsToGroupSave 

Process the addGroupsToGroup form.  Returns adminOnly unless the
current user canEdit this group.  Group GUIDs are passed in via the
form variable C<groups>.  Returns the user to the manageGroupsInGroup
screen.

=head3 $session

A WebGUI::Session object

=cut

sub www_addGroupsToGroupSave {
	my $session = shift;
	return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")) && $session->form->validToken);
	my $group = WebGUI::Group->new($session,$session->form->process("gid"));
	my @groups = $session->form->process('groups', 'group', []);
	$group->addGroups(\@groups);
	return www_manageGroupsInGroup($session);
}

#-------------------------------------------------------------------

=head2 www_addUsersToGroupSave 

Process the addUsersToGroup form.  Returns adminOnly unless the
current user canEdit this group.  User GUIDs are passed in via the
form variable C<users>.  Returns the user to the manageUsersInGroup
screen.

=head3 $session

A WebGUI::Session object

=cut

sub www_addUsersToGroupSave {
	my $session = shift;
        return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")) && $session->form->validToken);
        my @users = $session->form->selectList('users');
	my $group = WebGUI::Group->new($session,$session->form->process("gid"));
	$group->addUsers(\@users);
        return www_manageUsersInGroup($session);
}

#-------------------------------------------------------------------

=head2 www_autoAddToGroup 

Web facing method for users to automatically add themselves to a group.
Returns insufficient if the user is Visitor.  If the group exists and
has autoAdd set, adds the current user to the group.

=head3 $session

A WebGUI::Session object

=cut

sub www_autoAddToGroup {
	my $session = shift;
        return $session->privilege->noAccess() if ($session->user->isVisitor);
	my $group = WebGUI::Group->new($session,$session->form->process("groupId"));
	if ($group && $group->autoAdd) {
		$group->addUsers([$session->user->userId],[$session->form->process("groupId")]);
	}
	return "";
}

#-------------------------------------------------------------------

=head2 www_autoDeleteFromGroup 

Web facing method for users to automatically remove themselves from a group.
Returns insufficient if the user is Visitor.  If the group exists and
has autoDelete set, deletes the current user from the group.

=head3 $session

A WebGUI::Session object

=cut

sub www_autoDeleteFromGroup {
	my $session = shift;
        return $session->privilege->noAccess() if ($session->user->isVisitor);
	my $group = WebGUI::Group->new($session,$session->form->process("groupId"));
	if ($group && $group->autoDelete) {
		$group->deleteUsers([$session->user->userId],[$session->form->process("groupId")]);
	}
	return "";
}

#-------------------------------------------------------------------

=head2 www_deleteGroup

Delete's the group specified by id, in the form variable gid.  Groups 1-17
are reserved for WebGUI internal groups and are not allowed to be deleted.
Returns you to www_listGroups when done.

=head3 $session

A WebGUI::Session object

=cut

sub www_deleteGroup {
    my $session = shift;
    my $gid = $session->form->process("gid");
    return $session->privilege->adminOnly() unless (canEditGroup($session, $gid));
    return $session->privilege->vitalComponent() if WebGUI::Group->vitalGroup($gid);
    my $g = WebGUI::Group->new($session,$gid);
    $g->delete;
    return www_listGroups($session);
}

#-------------------------------------------------------------------

=head2 www_deleteGroupGrouping 

Web facing method for deleting a group from a group.  Returns adminOnly unless
the current user canEdit this group.  The group GUID to be deleted is passed in
via the form variable C<delete>.  Returns the user to the manageGroupsInGroup screen.

=head3 $session

A WebGUI::Session object

=cut

sub www_deleteGroupGrouping {
	my $session = shift;
	return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")));
	my $group = WebGUI::Group->new($session,$session->form->process("gid"));
	$group->deleteGroups([$session->form->process("delete")]);
	return www_manageGroupsInGroup($session);
}

#-------------------------------------------------------------------

=head2 www_deleteGrouping ( )

Deletes a set of users from a set of groups.  The user and group lists are expected
to be found in form fields names uid and gid, respectively.  Visitors are not
allowed to perform this operation.

=head3 $session

A WebGUI::Session object

=cut

sub www_deleteGrouping {
	my $session = shift;
        return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")) && $session->form->validToken);
        if (($session->user->userId eq $session->form->process("uid") || $session->form->process("uid") eq '3') && $session->form->process("gid") eq '3') {
                return $session->privilege->vitalComponent();
        }
        my @users = $session->form->selectList('uid');
        my @groups = $session->form->group("gid");
        foreach my $user (@users) {
                my $u = WebGUI::User->new($session,$user);
                $u->deleteFromGroups(\@groups);
        }
        return WebGUI::Operation::Group::www_manageUsersInGroup($session);
}
                                                                                                                                                       

#-------------------------------------------------------------------

=head2 www_editGroup 

Renders a form to add or edit groups.  Returns adminOnly unless the
current user canEdit this group.  The group GUID is passed in via
the form variable C<gid>.

=head3 $session

A WebGUI::Session object

=cut

sub www_editGroup {
	my $session = shift;
   my $rest = WebGUI::Session::Rest->new( session => $session );	
	my $i18n = WebGUI::International->new($session);
	my $groupId = $session->form->process("gid");
	
	return $rest->forbidden( $i18n->get(36) )
	   unless ( canEditGroup($session, $groupId ) );

	my $group = undef;
	if ( $groupId ){
		$group = WebGUI::Group->new( $session ,$groupId );
	} else {
		$group = WebGUI::Group->new($session,"");
	}

	my $output = {
		op => "editGroupSave",
		id => $groupId,
		groupName => {
			label => $i18n->get(84),
			value => $group->name,
			description => $i18n->get('84 description')			  
		},
		description => {
			label => $i18n->get(85),
			value => $group->description,
			description => $i18n->get('85 description')			  
		},
		isEditable => {
			label => $i18n->get('is editable'),
			value => $group->isEditable,
			description => $i18n->get('is editable help')					
		},
		showInForms => {
			label => $i18n->get('show in forms'),
			value => $group->showInForms,
			description => $i18n->get('show in forms help')					
		},
		expireOffset => {
			label => $i18n->get(367),
			value => $session->datetime->secondsToExactInterval( $group->expireOffset ),
			description => $i18n->get('367 description')				
		},
		unitsOfTime => {
			seconds => $i18n->get(704),
			minutes => $i18n->get(705),
			hours   => $i18n->get(706),
			days    => $i18n->get(700),
			weeks   => $i18n->get(701),
			months  => $i18n->get(702),
			years   => $i18n->get(703)
      },		
		expireNotify => {
			label => $i18n->get(865),
			value => $group->expireNotify,
			description => $i18n->get('865 description')			
		},
		expireNotifyOffset => {
			label => $i18n->get(864),
			value => $group->expireNotifyOffset,
			description => $i18n->get('864 description')			
		},
		expireNotifyMessage => {
			label => $i18n->get(866),
			value => $group->expireNotifyMessage,
			description => $i18n->get('866 description')			
		},
		deleteOffset => {
			label => $i18n->get(863),
			value => $group->deleteOffset,
			description => $i18n->get('863 description')			
		},
		ipFilter => {
			label => $i18n->get(857),
			value => $group->ipFilter,
			description => $i18n->get('857 description')			
		},
		scratchFilter => {
			label => $i18n->get(945),
			value => $group->scratchFilter,
			description => $i18n->get('945 description')			
		},				
		databaseLink => {
			label => '',
			value => $group->databaseLinkId,
			description => ''			
		},
		dbQuery => {
			label => $i18n->get(1005),
			value => $group->dbQuery,
			description => $i18n->get('1005 description')			
		},		
		ldapGroup => {
			label => $i18n->get("LDAPLink_ldapGroup","AuthLDAP"),
			value => $group->ldapGroup,
			description => $i18n->get("LDAPLink_ldapGroup description","AuthLDAP")			
		},				
		ldapGroupProperty => {
			label => $i18n->get("LDAPLink_ldapGroupProperty","AuthLDAP"),
			value => $group->ldapGroupProperty,
			default => "member",
			description => $i18n->get("LDAPLink_ldapGroupProperty description","AuthLDAP")			
		},					
		ldapRecursiveProperty => {
			label => $i18n->get("LDAPLink_ldapRecursiveProperty","AuthLDAP"),
			value => $group->ldapRecursiveProperty,
			description => $i18n->get("LDAPLink_ldapRecursiveProperty description","AuthLDAP")			
		},
		ldapRecursiveFilter => {
			label => $i18n->get("LDAPLink_ldapRecursiveFilter","AuthLDAP"),
			value => $group->ldapRecursiveFilter,
			description => $i18n->get("LDAPLink_ldapRecursiveFilterDescription","AuthLDAP")			
		},
		groupCacheTimeout => {
			label => $i18n->get(1004),
			value => $group->groupCacheTimeout,
			description => $i18n->get('1004 description')		
		},
		
		
	};

	# Conditional input, autoadd during save process unless the group is not 3
	if ( $groupId ne "3") {
		$output->{autoAdd} = {
			label => $i18n->get(974),
			value => $group->autoAdd,
			description => $i18n->get('974 description')				
		};
		
		$output->{autoDelete} = {
			label => $i18n->get(975),
			value => $group->autoDelete,
			description => $i18n->get('975 description')				
		};

	}		
	
	# Karmafied???
	if ( $session->setting->get("useKarma") ){
		$output->{karmaThreshold} = {
			label => $i18n->get(538),
			value => $group->karmaThreshold,
			description => $i18n->get('538 description')				
		};		

	}	
	
	# The LDAP portion
   tie my %links, "Tie::IxHash";
	%links = %{WebGUI::LDAPLink->getList($session)};
	%links = (""=>$i18n->get("noldaplink"),%links);   
	$output->{ldapLinkId} = {
		label => $i18n->get("ldapConnection","AuthLDAP"),
		value => $group->ldapLinkId,
		description => $i18n->get("ldapConnection description","AuthLDAP"),
		options => \%links
	};		

	$rest->data( $output );
   return $rest->response;
}

#-------------------------------------------------------------------

=head2 www_editGroupSave 

Process the editGroup form.  Returns adminOnly unless the current
user canEdit this group.  The GUID of the group is passed in via the
form variable C<gid>.

Returns the user to the list of groups.

=head3 $session

A WebGUI::Session object

=cut

sub www_editGroupSave {
	my $session = shift;
   my $rest = WebGUI::Session::Rest->new( session => $session );	
	my $i18n = WebGUI::International->new($session);
	my $groupId = $session->form->process("gid") || 'new';
	
	return $rest->forbidden( $i18n->get(36) )
	   unless ( canEditGroup( $session, $groupId ) && $session->form->validToken );
	
   my $group = WebGUI::Group->new($session, $groupId);
   # We don't want them to use an existing name.  If needed, we'll add a number to the name to keep it unique.
   my $groupName = $session->form->process("groupName");
   while ( my $existingGroupId = WebGUI::Group->find($session, $groupName)->getId ) {
      last
         if $existingGroupId eq $groupId;
      $groupName =~ s/\A(.*?)(\d*)\z/
         my $newNum = ($2 || 0) + 1;
         substr($1, 0, 100 - length($newNum)) . $newNum;  #prevent name from growing over 100 chars
      /emsx;
   }
   $group->name($groupName);
   $group->description($session->form->process("description"));
   $group->expireOffset($session->form->interval("expireOffset"));
	$group->karmaThreshold($session->form->process("karmaThreshold"));
	$group->isEditable($session->form->process("isEditable"));
	$group->showInForms($session->form->process("showInForms"));
	$group->ipFilter($session->form->process("ipFilter"));
	$group->scratchFilter($session->form->process("scratchFilter"));
	$group->expireNotify($session->form->yesNo("expireNotify"));
	$group->expireNotifyOffset($session->form->process("expireNotifyOffset"));
	$group->expireNotifyMessage($session->form->process("expireNotifyMessage"));
	$group->deleteOffset($session->form->process("deleteOffset"));
	$group->autoAdd($session->form->yesNo("autoAdd"));
	$group->autoDelete($session->form->yesNo("autoDelete"));
	$group->databaseLinkId($session->form->process("databaseLinkId"));
	$group->dbQuery($session->form->process("dbQuery"));
	$group->groupCacheTimeout($session->form->interval("groupCacheTimeout"));
	$group->ldapLinkId($session->form->selectBox("ldapLinkId"));
	$group->ldapGroup($session->form->text("ldapGroup"));
	$group->ldapGroupProperty($session->form->text("ldapGroupProperty"));
	$group->ldapRecursiveProperty($session->form->text("ldapRecursiveProperty"));
	$group->ldapRecursiveFilter($session->form->process("ldapRecursiveFilter"));
	$rest->data( { id => $group->getId } );
   return $rest->response;
}

#-------------------------------------------------------------------

=head2 www_editGrouping 

Renders a form for the properties of a user being in a group, namely
their expire date and whether or not they are an admin for this
group.  The userId and groupId are passed in via the C<uid> and C<gid>
form variables, respectively.

=head3 $session

A WebGUI::Session object

=cut

sub www_editGrouping {
    my $session = shift;
    my $uid = $session->form->process('uid');
    my $gid = $session->form->process('gid');
    return $session->privilege->adminOnly()
        unless canEditGroup($session, $gid);
    my $i18n = WebGUI::International->new($session);
    my $f = WebGUI::HTMLForm->new($session);
    $f->submit;
    $f->hidden(
        -name => "op",
        -value => "editGroupingSave"
    );
    $f->hidden(
        -name => "uid",
        -value => $uid,
    );
    $f->hidden(
        -name => "gid",
        -value => $gid,
    );
    my $u = WebGUI::User->new($session,$uid);
    my $g = WebGUI::Group->new($session,$gid);
    $f->readOnly(
        -value => $u->username,
        -label => $i18n->get(50),
        -hoverHelp => $i18n->get('50 description'),
    );
    $f->readOnly(
        -value => $g && $g->name,
        -label => $i18n->get(84),
        -hoverHelp => $i18n->get('84 description'),
    );
    $f->date(
        -name => "expireDate",
        -label => $i18n->get(369),
        -hoverHelp => $i18n->get('369 description'),
        -value => $g && $g->userGroupExpireDate($uid),
    );
    $f->yesNo(
        -name=>"groupAdmin",
        -label=>$i18n->get(977),
        -hoverHelp=>$i18n->get('977 description'),
        -value=> $g && $g->userIsAdmin($uid),
    );
    $f->submit;
    return _submenu($session,$f->print,'370');
}

#-------------------------------------------------------------------

=head2 www_editGroupingSave 

Process the editGrouping form.  Returns adminOnly unless the current
user can edit this group.  Returns the user to the manageUsersInGroup
screen.

=head3 $session

A WebGUI::Session object

=cut

sub www_editGroupingSave {
	my $session = shift;
	return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")) && $session->form->validToken);
	my $group = WebGUI::Group->new($session,$session->form->process("gid"));
        $group->userGroupExpireDate($session->form->process("uid"),$session->datetime->setToEpoch($session->form->process("expireDate")));
        $group->userIsAdmin($session->form->process("uid"),$session->form->process("groupAdmin"));
        return www_manageUsersInGroup($session);
}

#-------------------------------------------------------------------

=head2 www_emailGroup 

Render a form where an email can be sent to all members of a group.
Returns adminOnly unless the current user canEdit this group.

=head3 $session

A WebGUI::Session object

=cut

sub www_emailGroup {
	my $session = shift;
	return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")));
	my ($output,$f);
	my $i18n = WebGUI::International->new($session);
    my $group = WebGUI::Group->new($session,$session->form->process("gid"));
	$f = WebGUI::HTMLForm->new($session);
	$f->hidden(
		-name => "op",
		-value => "emailGroupSend"
	);
	$f->hidden(
		-name => "gid",
		-value => $session->form->process("gid")
	);
        $f->readOnly(
        -label => $i18n->get(379),
        -value => $group->getId,
    );
    $f->readOnly(
        -label => $i18n->get(84),
        -value => $group->name,
    );
	$f->email(
		-name=>"from",
		-value=>$session->setting->get("companyEmail"),
		-label=>$i18n->get(811),
		-hoverHelp=>$i18n->get('811 description'),
		);
	$f->text(
		-name=>"subject",
		-label=>$i18n->get(229),
		-hoverHelp=>$i18n->get('229 description'),
		);
	$f->yesNo(
		-name=>'override',
		-label=>$i18n->get('override user email preference'),
		-hoverHelp=>$i18n->get('override user email preference description'),
		);
	$f->HTMLArea(
		-name=>"message",
		-label=>$i18n->get(230),
		-hoverHelp=>$i18n->get('230 description'),
		);
	$f->submit($i18n->get(810));
	$output = $f->print;
	return _submenu($session,$output,'809');
}

#-------------------------------------------------------------------

=head2 www_emailGroupSend 

Processes the emailGroup form.  Returns adminOnly unless the current
user canEdit this group.

=head3 $session

A WebGUI::Session object

=cut

sub www_emailGroupSend {
	my $session = shift;
	my $f = $session->form;
	return $session->privilege->adminOnly()
		unless (canEditGroup($session,$f->get('gid')) && $f->validToken);

	WebGUI::Inbox::Message->create(
		$session, {
			groupId                 => $f->get('gid'),
			subject                 => $f->get('subject'),
			status                  => 'unread',
			message                 => $f->process('message', 'HTMLArea'),
			sentBy                  => $session->user->userId,
			overridePerUserDelivery => $f->get('override'),
			extraHeaders            => { from => $f->get('from') }
		}
	);
	my $i18n = WebGUI::International->new($session);
	return _submenu($session,$i18n->get(812));
}

#-------------------------------------------------------------------

=head2 www_listGroups 

Render a paginated list of all groups.  If more than 250 groups exist,
then it will show only a search form.  The list of groups will only
show that groups that a user canEdit.

=head3 $session

A WebGUI::Session object

=cut

sub www_listGroups {
	my $session = shift;
	my $i18n = WebGUI::International->new($session);
	my $rest = WebGUI::Session::Rest->new( session => $session );
   my $webParams = $session->request->parameters->mixed;
	if ( canEditAll($session) ) {		
      my @sqlParams = ();
      my @likableItemPositions = ();
      my $searchParam = "";      
      my $search = $session->form->param('sSearch');
      if ( $search ){
         $searchParam = q|and groupName like ?|;
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

      my $sqlCommand = qq|select groupId,groupName,description from groups where isEditable=1 $searchParam order by groupName $limitParam|;
            
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
              groupId     => $data->{groupId},
              groupName   => $data->{groupName},
              description => $data->{description}
         });
      }
      my $rowCount = @{ $output };
      
      $sqlCommand = qq|select count(*) from groups where isEditable=1|;      
      
      $webParams->{iTotalRecords} = $session->db->quickScalar( $sqlCommand ); # Kind of overkill but required for pagination.  total records in database
      $webParams->{iTotalDisplayRecords} = $rowCount; #Total records, after filtering
      $webParams->{data} = $output;
      $rest->data( $webParams );
      return $rest->response;		
			
	} elsif ( canView($session) ) {
      my @sqlParams = ();
      my @likableItemPositions = ();
      my $searchParam = undef;      
      my $search = $session->form->param('sSearch');
      if ( $search ){
         $searchParam = q|and groupId not in ( ? )|;
         push(@likableItemPositions, scalar( @sqlParams ) );
         push(@sqlParams, $search);
      }
      
      my $limitParam = undef;
      my $start = $session->form->param('iDisplayStart');
      my $length = $session->form->param('iDisplayLength');
      if ( $length ){
         $limitParam = qq| LIMIT ?, ?|;
         push(@sqlParams, $start);         
         push(@sqlParams, $length);
      }

      my $sqlCommand = qq|select groupId,groupName,description from groups where isEditable=1 $searchParam order by groupName $limitParam|;
            
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
              groupId     => $data->{groupId},
              groupName   => $data->{groupName},
              description => $data->{description}
         });
      }
      my $rowCount = @{ $output };
      
      $sqlCommand = qq|select count(*) from groups where isEditable=1|;      
      
      $webParams->{iTotalRecords} = $session->db->quickScalar( $sqlCommand ); # Kind of overkill but required for pagination.  total records in database
      $webParams->{iTotalDisplayRecords} = $rowCount; #Total records, after filtering
      $webParams->{data} = $output;
      $rest->data( $webParams );
      return $rest->response;		

	}else {
      $rest->message( $i18n->get(36) );
      return $rest->forbidden;
		
   }
}


#-------------------------------------------------------------------

=head2 www_manageGroupsInGroup 

Render a list of all groups in this group, by hierarchy and a form
for adding and removing groups.

=head3 $session

A WebGUI::Session object

=cut

sub www_manageGroupsInGroup {
	my $session = shift;
    my $i18n = WebGUI::International->new($session);
    my $group = WebGUI::Group->new($session,$session->form->process("gid"));
    return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")));

    my $f = WebGUI::HTMLForm->new($session);
	$f->submit;
        $f->hidden(
		-name => "op",
		-value => "addGroupsToGroupSave"
	);
    $f->hidden(
		-name => "gid",
		-value => $session->form->process("gid")
	);
    $f->readOnly(
        -label => $i18n->get(379),
        -value => $group->getId,
    );
    $f->readOnly(
        -label => $i18n->get(84),
        -value => $group->name,
    );

	my @groups;
	my $groupsIn = $group->getGroupsIn(1);
	my $groupsFor = $group->getGroupsFor;
	push(@groups, @$groupsIn,@$groupsFor,$session->form->process("gid"));
    $f->group(
		-name=>"groups",
		-excludeGroups=>\@groups,
		-label=>$i18n->get(605),
		-size=>5,
		-multiple=>1,
        -defaultValue=>[],
		);
    $f->submit;
    my $output = $f->print;
	$output .= '<p />';
	$output .= walkGroups($session, $session->form->process("gid"));
	return _submenu($session,$output,'813');
}

#-------------------------------------------------------------------

=head2 www_manageUsersInGroup

Renders a form that displays all users in this group, as well as a
list of users that can be added to this group.  Returns adminOnly
unless the current user canEdit this group.

=head3 $session

A WebGUI::Session object

=cut

sub www_manageUsersInGroup {
	my $session = shift;
    return $session->privilege->adminOnly() unless (canEditGroup($session,$session->form->process("gid")));
	my $i18n = WebGUI::International->new($session);
	my $output = WebGUI::Form::formHeader($session)
		.WebGUI::Form::hidden($session,{
			name=>"gid",
			value=>$session->form->process("gid")
			})
		.WebGUI::Form::hidden($session,{
			name=>"op",
			value=>"deleteGrouping"
			});
        $output .= '<table border="1" cellpadding="2" cellspacing="0"><tr><td class="tableHeader"><input type="image" src="'
		.$session->icon->getBaseURL().'delete.gif" border="0"></td>
                <td class="tableHeader">'.$i18n->get(50).'</td>
                <td class="tableHeader">'.$i18n->get(369).'</td></tr>';
	my $p = WebGUI::Paginator->new($session,$session->url->page("op=manageUsersInGroup;gid=".$session->form->process("gid")));
        $p->setDataByQuery("select users.username,users.userId,groupings.expireDate
                from groupings,users where groupings.groupId=".$session->db->quote($session->form->process("gid"))." and groupings.userId=users.userId
                order by users.username");
	foreach my $row (@{$p->getPageData}) {
                $output .= '<tr><td>'
			.WebGUI::Form::checkbox($session,{
				name=>"uid",
				value=>$row->{userId}
				})
                        .$session->icon->edit('op=editGrouping;uid='.$row->{userId}.';gid='.$session->form->process("gid"))
                        .'</td>';
                $output .= '<td class="tableData"><a href="'.$session->url->page('op=editUser;uid='.$row->{userId}).'">'.$row->{username}.'</a></td>';
                $output .= '<td class="tableData">'.$session->datetime->epochToHuman($row->{expireDate},"%z").'</td></tr>';
        }
        $output .= '</table>'.WebGUI::Form::formFooter($session,);
	$output .= $p->getBarTraditional;
	$output .= '<p><h1>'.$i18n->get(976).'</h1>';
	$output .= WebGUI::Operation::User::getUserSearchForm($session, "manageUsersInGroup",{gid=>$session->form->process("gid")});
	my ($userCount) = $session->db->quickArray("select count(*) from users");
	return _submenu($session,$output) unless ($session->form->process("doit") || $userCount < 250 || $session->form->process("pn") > 1);
	my $f = WebGUI::HTMLForm->new($session);
	$f->submit;
	$f->hidden(
		-name => "gid",
		-value => $session->form->process("gid")
	);
	$f->hidden(
		-name => "op",
		-value => "addUsersToGroupSave"
	);
	my $group = WebGUI::Group->new($session,$session->form->process("gid"));
    $f->readOnly(
        -label => $i18n->get(379),
        -value => $group->getId,
    );
    $f->readOnly(
        -label => $i18n->get(84),
        -value => $group->name,
    );

	my $existingUsers = $group->getUsers;
	push(@{$existingUsers},"1");
	my %users;
	tie %users, "Tie::IxHash";
	my $sth = WebGUI::Operation::User::doUserSearch($session, "op=manageUsersInGroup;gid=".$session->form->process("gid"),0,$existingUsers);
	while (my $data = $sth->hashRef) {
		$users{$data->{userId}} = $data->{username};
		$users{$data->{userId}} .= " (".$data->{email}.")" if ($data->{email});
	}
	$sth->finish;
	$f->selectList(
		-name=>"users",
		-label=>$i18n->get(976),
		-options=>\%users,
		-multiple=>1,
		-size=>7
		);
	$f->submit;
	$output .= $f->print;
        return _submenu($session,$output,'88');
}

1;

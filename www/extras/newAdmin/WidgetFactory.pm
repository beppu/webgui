package WebGUI::Macro::WidgetFactory;

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
use WebGUI::Asset::Template;

=head1 NAME

Package WebGUI::Macro::WidgetFactory

=head1 DESCRIPTION

Handy example code for starting a new Macro when you have to start from scratch.

=head2 process( $session, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item *

A session variable

=item *

Any other options that were sent to the macro by the user.  It is up to you to set defaults and
to validate user input.

=back

=cut


#-------------------------------------------------------------------
sub process {
   my $session = shift;
   my $columnConfig = [
     { column => "userId",       title => "UserId" },
     { column => "lastIP",       title => "Last Ip" },
     { column => "lastPageView", title => "Last View" },
     { column => "username",     title => "Username" },
     { column => "expires",      title => "Expires" },
	  { column => "sessionId",    title => "Kill Session", checkbox => "1", cssClass => "killSession", name => 'killSession' }
   ];
	
   my $datatable = WebGUI::Form::DataTablesNet->new(
      $session, { columnConfig => $columnConfig, noScript => 1, restDataUrl => "/?op=viewActiveSessions", id => "sessionsDatatable" }
   );
   return $datatable->toHtml();

}

1;

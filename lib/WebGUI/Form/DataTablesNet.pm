package WebGUI::Form::DataTablesNet;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2012 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Form::Control';
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::DataTablesNet

=head1 DESCRIPTION

Create an html table based on: http://www.datatables.net/

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Control.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the super class for additional details.

=cut

sub definition {
    my $class      = shift;
    my $session    = shift;
    my $definition = shift || [];
    ## You can add some sensible configurable parameters and defaults here
    push @{ $definition }, {
       columnConfig  => { defaultValue => undef },
       config        => { defaultValue => undef },
       cssClasses    => { defaultValue => 'webguiAdminTable' },
       id            => { defaultValue => 'DBASH-' . $session->id->generate() }, # Required if the noScript option is set, do NOT use the defaultValue
       noScript      => { defaultValue => undef }, # Supress the <table...</table> and <script...</script> tags
       templateId    => { defaultValue => 'DBASH-0000000000000001' },
       restDataParam => { defaultValue => 'data'},
       restDataUrl   => { defaultValue => undef, },
       restDeleteUrl => { defaultValue => undef, },
       restCreateUrl => { defaultValue => undef, },
       restUpdateUrl => { defaultValue => undef, },
       dateFormat    => { defaultValue => $session->user->get('dateFormat') || '%y-%m-%d' }  # use user setting  or...
    };
    return $class->SUPER::definition( $session, $definition );
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the name of the form control.

=cut

sub getName {
    my ( $class, $session ) = @_;
    return WebGUI::International->new( $session, "Form_DataTablesNet" )->get( "topicName" );
}

#-------------------------------------------------------------------

=head2 getValueAsHtml ( )

Render the datatable.

=cut

sub getValueAsHtml {
    my $this = shift;
    return $this->toHtml();
}

#-------------------------------------------------------------------

=head2 toHtml ( )

Render the Datatable.

=cut

sub toHtml {
    my $this = shift;
    
    my $content =  {
       config   => $this->get('config'), # Use this if a configuration is provided, remember it is rendered as in html
       columns  => $this->get('columnConfig'),
       data     => $this->get('restDataParam'), 
       noScript => $this->get('noScript'),
       table    => { id => $this->get('id'), class => $this->get('cssClasses') },
       url      => {  list => $this->get('restDataUrl'),
                    create => $this->get('restCreateUrl'),
                    update => $this->get('restUpdateUrl'),
                    delete => $this->get('restDeleteUrl') }
    };
    
    return WebGUI::Asset::Template->newById( $this->session, $this->get('templateId') )->process( $content );
}

1;


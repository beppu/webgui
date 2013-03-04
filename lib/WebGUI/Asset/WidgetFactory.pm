package WebGUI::Asset::WidgetFactory;

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
use WebGUI::Macro;

use Moose;
use WebGUI::Definition::Asset;
extends 'WebGUI::Asset';
define assetName => ['assetName', 'Asset_WidgetFactory'];
define icon      => 'page_component.gif';
define tableName => 'webwidgetfactory';
property widgetType => (
    tab          => "properties",
    label        => ['widgetType', 'Asset_WidgetFactory'],
    hoverHelp    => ['widget description', 'Asset_WidgetFactory'],
    fieldType    => 'selectBox',
    default      => 'DBASH-0000000000002',
    options      => \&getWidgets,
         );
has '+uiLevel' => (
    default => 9,
);
sub getWidgets{
   my $session = shift->session;
	my $i18n = WebGUI::International->new($session, "Asset_WidgetFactory");
   return {
      'DBASH-0000000000001' => 'DataTable',       
      'DBASH-0000000000002' => 'Grid',       
   };
}


=head1 NAME

Package WebGUI::Asset::WebWidgetFactory 

=head1 DESCRIPTION

Provides a mechanism to create Widgets in the browser.

=head1 SYNOPSIS

use WebGUI::Asset::WebWidgetFactory;


=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 exportHtml_view

Override the method from AssetExportHtml to handle the redirect.

=cut

sub exportHtml_view {
   my $self = shift;
   return $self->session->privilege->noAccess() unless $self->canView;
   #WebGUI::Macro::process($self->session, \$url);
	return 'Working';# if ($url eq $self->url);
	#return $self->session->style->process('', 'PBtmpl0000000000000060');
}

#-------------------------------------------------------------------

=head2 view ( )

Display the redirect url when in admin mode.

=cut

sub view {
	my $self = shift;
	#$self->session->isAdminOn

	return "should be view";

}

#-------------------------------------------------------------------

=head2 www_view

A web executable method that redirects the user to the specified page, or displays the edit interface when admin mode is enabled.

=cut

sub www_view {
    my $self = shift;
    return $self->session->privilege->noAccess() unless $self->canView;
	 my $i18n = WebGUI::International->new($self->session, "Asset_WebWidgetFactory");
    
    #WebGUI::Macro::process($self->session, \$url);
   # if ($self->session->isAdminOn() && $self->canEdit) {
       
   return '<h1>New Asset Dan</h1>Create table here!';

}

__PACKAGE__->meta->make_immutable;
1;


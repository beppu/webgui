package WebGUI::Form::CsrfToken;

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
use base 'WebGUI::Form::Hidden';
use WebGUI::International;
use JSON;

=head1 NAME

Package WebGUI::Form::CsrfToken

=head1 DESCRIPTION

Creates a hidden field to use for CSRF prevention..

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Hidden.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut


#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'WebGUI')->get('csrfToken');
}

#-------------------------------------------------------------------

=head2 toHtmlAsHidden ( )

Renders an input tag of type hidden.

=cut

sub toHtmlAsHidden {
	my $self = shift;
    $self->set('name',  'webguiCsrfToken');
    $self->set('value', $self->session->scratch->get('webguiCsrfToken'));
	return $self->SUPER::toHtmlAsHidden();
}

#-------------------------------------------------------------------

=head2 toJson

=cut

sub toJson {
    my $self = shift;
    my $structure = $_[0] || { };
    $structure->{name} = 'webguiCsrfToken';
    $structure->{value} = $self->session->scratch->get('webguiCsrfToken');
    $structure->{type} = ref $self;
    if( ! $_[0] ) {
        return encode_json $structure;
    } else {
        return $structure;
    }

}

1;


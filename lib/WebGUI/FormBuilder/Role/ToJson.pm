package WebGUI::FormBuilder::Role::ToJson;

use strict;
use Moose::Role;
use WebGUI::Exception;
use Carp qw(confess);
use JSON;

=head1 METHODS

=head2 toJson

XXX

=cut

sub toJson {
    my $self = shift;
    my $structure = shift;

    my $root = $structure ? 0 : 1;  # when toJson() calls toJson(), it returns a hashref rather than JSON text
warn "toJson: root: $root class: " . ref $self;

    $structure ||= { };

    $structure->{ name  } = $self->can('name')  ? $self->name  : '';
    $structure->{ label } = $self->can('label') ? $self->label : '';

    $structure->{type} = ref $self;

    if ( $self->DOES('WebGUI::FormBuilder::Role::HasFields') ) {
        my @fields;
        for my $field ( @{$self->fields} ) {
            my $sub_structure = { };
            push @fields, $sub_structure;
            $field->toJson( $sub_structure );
        }
        $structure->{fields} = \@fields;
    }

    if ( $self->DOES('WebGUI::FormBuilder::Role::HasFieldsets') ) {
        my @fieldsets;
        for my $fieldset ( @{$self->fieldsets} ) {
            my $sub_structure = { };
            push @fieldsets, $sub_structure;
            $fieldset->toJson( $sub_structure );
        }
        $structure->{fieldsets} = \@fieldsets;
    }

    if ( $self->DOES('WebGUI::FormBuilder::Role::HasTabs') ) {
        my @tabsets;
        for my $tabset ( @{$self->tabsets} ) {
            my $sub_structure = { };
            push @tabsets, $sub_structure;
            $tabset->toJson( $sub_structure );
        }
        $structure->{tabsets} = \@tabsets;
    }

    if ( $self->isa('WebGUI::FormBuilder::Tabset') ) {
        my @tabs;
        for my $tab ( @{$self->tabs} ) {
            my $sub_structure = { };
            push @tabs, $sub_structure;
            $tab->toJson( $sub_structure );
        }
        $structure->{tabs} = \@tabs;
    }

    if ( $self->isa('WebGUI::TabForm') ) {
        for my $tab_name ( keys %{ $self->{_tab} } ) {
            my $sub_structure = { };
            $self->{_tab}->{$tab_name}->toJson( $sub_structure );
            push @{ $structure->{tabs} }, $sub_structure; # XXX also pushing these onto $structure->{tab} as above even though I'm really not sure what kind of objects there are and whether they actually have a toJson method
        }
    }

    if( $root ) {
        return encode_json $structure;
    } else {
        return $structure;
    }

}

=head2 fromJson

XXX

Call on an existing object of the correct type, such as an L<WebGUI::WebGUI::FormBuilder>.
Returns a hash of key => value pairs.

=cut

sub fromJson {
    my $self = shift;
    my $structure = shift;
    my $not_root = shift;

    $structure = decode_json $structure if ! $not_root;

}


1;

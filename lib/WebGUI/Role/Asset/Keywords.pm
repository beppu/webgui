package WebGUI::Role::Asset::Keywords;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use Moose::Role;

# define tableName           => '...';

=head1 NAME

Package WebGUI::Role::Asset::Keywords

=head1 DESCRIPTION

Extend C<< get() >> and C<< set() >> to return and accept C<< keywords >> parameters.

=head1 SYNOPSIS

 with 'WebGUI::Role::Asset::Keywords';
 $self->set( keywords => '...');
 ... $self->get()->{keywords}

=cut

around set => sub {
warn "set2";
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_);
    my $properties = @_ % 2 ? $_[0] : { @_ };
    if(exists $properties->{keywords}) {
warn "set: handling a keyword: ``$properties->{keywords}''";
        $self->keywords($properties->{keywords});
    }
};

around get => sub {
warn "get2";
    my $orig = shift;
    my $self = shift;
    if( @_ and $_[0] eq 'keywords' ) {
warn "get: handling a keyword: ``@{[ $self->keywords ]}''";
        return $self->keywords;
    }
    my $properties = $self->$orig(@_);
    $properties->{keywords} = $self->keywords;
    return $properties;
};


1;


package WebGUI::Workflow::Activity::CleanCHICache;


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
use base 'WebGUI::Workflow::Activity';
use WebGUI::Cache::CHI;

=head1 NAME

Package WebGUI::Workflow::Activity::CleanCHICache

=head1 DESCRIPTION

This activity deletes entries from the CHI cache if the cache size has gotten too big.

=head1 SYNOPSIS

See WebGUI::Workflow::Activity for details on how to use any activity.

=head1 METHODS

These methods are available from this class:

=cut


#-------------------------------------------------------------------

=head2 definition ( session, definition )

See WebGUI::Workflow::Activity::definition() for details.

=cut 

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session, "Workflow_Activity_CleanCHICache");
warn "i18n: " . $i18n;
warn "activity name: " . $i18n->get("activityName"),
	push(@{$definition}, {
		name=>$i18n->get("activityName"),
		properties=> {
			sizeLimit => {
				fieldType=>"integer",
				label=>$i18n->get("size limit"),
				subtext=>$i18n->get("bytes"),
				defaultValue=>100000000,
				hoverHelp=>$i18n->get("size limit help")
				}
			}
		});
	return $class->SUPER::definition($session,$definition);
}


#-------------------------------------------------------------------

=head2 execute (  )

See WebGUI::Workflow::Activity::execute() for details.

=cut

sub execute {
	my $self = shift;
        my $size = $self->get("sizeLimit") + 10;
        my $cache = WebGUI::Cache->new($self->session);
        if( $cache->stats > $self->get('sizeLimit') ) {
            # CHI::Driver::HandlerSocket doesn't have an expires field (but probably should) so it's all, nothing, or random
            $cache->flush;
        }
	return $self->COMPLETE;
}



1;



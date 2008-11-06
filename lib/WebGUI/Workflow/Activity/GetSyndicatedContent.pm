package WebGUI::Workflow::Activity::GetSyndicatedContent;


=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2008 Plain Black Corporation.
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
use WebGUI::Asset::Wobject::SyndicatedContent;
use JSON;

=head1 NAME

Package WebGUI::Workflow::Activity::GetSyndicatedContent;

=head1 DESCRIPTION

Prefetches syndicated content URLs so that the pages can be served up more quickly.

=head1 SYNOPSIS

See WebGUI::Workflow::Activity for details on how to use any activity.

=head1 METHODS

These methods are available from this class:

=cut


#-------------------------------------------------------------------

=head2 definition ( session, definition )

See WebGUI::Workflow::Activity::defintion() for details.

=cut 

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session, "Asset_SyndicatedContent");
	push(@{$definition}, {
		name=>$i18n->get("get syndicated content"),
		properties=> { }
		});
	return $class->SUPER::definition($session,$definition);
}


#-------------------------------------------------------------------

=head2 execute (  )

See WebGUI::Workflow::Activity::execute() for details.

=cut

sub execute {
    my $self = shift;
    my $object = shift;
    my $instance = shift;
    unless (defined $instance) {
        $self->session->errorHandler->error("Could not instanciate Workflow Instance in GetSyndicatedContent Activity");
        return $self->ERROR;
    }
	my $log = $self->session->log;
    # start time to check for timeouts
    my $time = time();
    my $ttl  = $self->getTTL;

    my $assets = JSON->new->decode($instance->getScratch("syndicatedassets") || '[]');
	if (scalar @$assets < 1) {
		$assets = $self->session->db->buildArrayRef("select assetId from asset where className like 'WebGUI::Asset::Wobject::SyndicatedContent'");
	}
    while (my $id = shift(@{$assets})) {
        # Get RSS data, which will be stored in the cache
        $log->info("GetSyndicatedContent: Caching for $id");
		my $asset = WebGUI::Asset::Wobject::SyndicatedContent->new($self->session, $id);
		if (defined $asset) {
			my $feed = $asset->generateFeed;
			unless ($feed->isa('XML::FeedPP')) {
				$log->error("GetSyndicatedContent: Syndicated Content Asset $id returned an invalid feed");
			}
		}
		else {
			$log->error("GetSyndicatedContent: Couldn't instanciate $id")
		}
        # Check for timeout
        last if (time() - $time > $ttl);
    }

    # if there are urls left, we need to process again
    if (scalar(@$assets) > 0) {
        $instance->setScratch("syndicatedassets", JSON->new->encode($assets));
        return $self->WAITING;
    }
    $instance->deleteScratch("syndicatedassets");
    return $self->COMPLETE;
}




1;



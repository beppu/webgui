package WebGUI::Operation::Package;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2002 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use Exporter;
use strict qw(vars subs);
use WebGUI::Privilege;
use WebGUI::Session;
use WebGUI::Shortcut;
use WebGUI::SQL;
use WebGUI::URL;

our @ISA = qw(Exporter);
our @EXPORT = qw(&www_deployPackage &www_selectPackageToDeploy);

#-------------------------------------------------------------------
sub _duplicateWobjects {
	my ($sth, $wobject, $cmd, %hash, $extra, $w);
	$sth = WebGUI::SQL->read("select * from wobject where pageId=$_[0]");
        while ($wobject = $sth->hashRef) {
		$extra = WebGUI::SQL->quickHashRef("select * from ${$wobject}{namespace} where wobjectId=${$wobject}{wobjectId}");
		tie %hash, 'Tie::CPHash';
		%hash = (%{$wobject},%{$extra});
		$wobject = \%hash;
                $cmd = "WebGUI::Wobject::".${$wobject}{namespace};
                $w = $cmd->new($wobject);
		$w->duplicate($_[1]);
        }
        $sth->finish;
}

#-------------------------------------------------------------------
sub _recursePageTree {
        my ($a, %package, %newParent, $newPageId, $urlizedTitle);
	tie %newParent, 'Tie::CPHash';
	tie %package, 'Tie::CPHash';
	%newParent = WebGUI::SQL->quickHash("select * from page where pageId=$_[1]");
	_duplicateWobjects($_[0],$_[1]);
        $a = WebGUI::SQL->read("select * from page where parentId=$_[0]");
        while (%package = $a->hash) {
		$newPageId = getNextId("pageId");
		$urlizedTitle = WebGUI::URL::makeUnique($package{urlizedTitle});
                WebGUI::SQL->write("insert into page values ($newPageId,$_[1],".quote($package{title}).",$newParent{styleId},$session{user}{userId},$newParent{ownerView},$newParent{ownerEdit},$newParent{groupId},$newParent{groupView},$newParent{groupEdit},$newParent{worldView},$newParent{worldEdit},$package{sequenceNumber},".quote($package{metaTags}).",".quote($urlizedTitle).",$package{defaultMetaTags},".quote($package{template}).",".quote($package{menuTitle}).",".quote($package{synopsis}).")");
                _recursePageTree($package{pageId},$newPageId);
        }
        $a->finish;
}

#-------------------------------------------------------------------
sub www_selectPackageToDeploy {
        my ($output, %data, $sth, $flag);
        if (WebGUI::Privilege::canEditPage()) {
		tie %data,'Tie::CPHash';
                $output = helpLink(30);
		$output .= '<h1>'.WebGUI::International::get(375).'</h1>';
		$output .= '<ul>';
		$sth = WebGUI::SQL->read("select * from page where parentId=5");
		while (%data = $sth->hash) {
			$output .= '<li> <a href="'.WebGUI::URL::page('op=deployPackage&pid='.$data{pageId})
				.'">'.$data{title}.'</a>';
			$flag = 1;
		}
		$sth->finish;
		$output .= WebGUI::International::get(377) unless $flag;
		$output .= '</ul>';
                return $output;
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------
sub www_deployPackage {
        if (WebGUI::Privilege::canEditPage()) {
		_recursePageTree($session{form}{pid},$session{page}{pageId});
		return "";
	} else {
		return WebGUI::Privilege::insufficient();
	}
}

1;


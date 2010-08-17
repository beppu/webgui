#!/usr/bin/perl

use strict;
use warnings;

if($ARGV[0] eq '-h' or $ARGV[0] eq '--help') {
    die "$0: eg, $0 Test::WebGUI::Asset::Template";
}

my $package = shift @ARGV or die "specify Test:: package";

use lib '/data/WebGUI/t/lib';
use Test::Class::Load '/data/WebGUI/t/tests/';

$package->new->runtests();



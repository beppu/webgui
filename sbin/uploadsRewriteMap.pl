#!/data/wre/prereqs/bin/perl

use strict;
use warnings;

my $root;
BEGIN {
    $root = '/data/WebGUI';
}
use lib "$root/lib";

# add custom lib directories to library search path
unshift @INC, grep {
    if (!-d $_) {
        warn "WARNING: Not adding lib directory '$_' from $root/sbin/preload.custom: Directory does not exist.\n";
        0;
    }
    else {
        1;
    }
} readLines($root."/sbin/preload.custom");

use constant DEBUG => 0;

use WebGUI::Session;
use CGI::Cookie;
use IO::Handle;

$|++;
my $log;
open $log, '>>', '/tmp/uploads_rewrite_log' if DEBUG;
$log->autoflush(1) if DEBUG;

while ( my $line = <STDIN> ) {
    chomp $line;
    my ($conf, $path, $cook) = split /%%/, $line, 3;
    my $return = checkUploads($conf, $path, $cook);
    print {$log} ($return ? "=== ALLOWED\n" : "=== DENIED\n") if DEBUG;
    print $return ? "1\n" : "0\n";
}

sub checkUploads {
    my ($conf, $path, $cook) = @_;
    print {$log} "========== checking $path\n" if DEBUG;
    return 1
        unless -e $path;
    print {$log} "exists, continuing checks\n" if DEBUG;
    $path =~ s{[^/]*$}{};
    return 1
        unless -e $path . '.wgaccess';
    print {$log} "wgaccess file exists, continuing checks\n" if DEBUG;

    open my $FILE, '<' , $path . '.wgaccess';
    my $fileContents = do { local $/; <$FILE> };
    close($FILE);

    my @users;
    my @groups;
    my @assets;
    if ($fileContents =~ /\A(?:\d+|[A-Za-z0-9_-]{22})\n(?:\d+|[A-Za-z0-9_-]{22})\n(?:\d+|[A-Za-z0-9_-]{22})/) {
        print {$log} "old style\n" if DEBUG;
        my @privs = split("\n", $fileContents);
        push @users, $privs[0];
        push @groups, @privs[1,2];
    }
    else {
        print {$log} "new style\n" if DEBUG;
        my $privs = JSON->new->decode($fileContents);
        @users = @{ $privs->{users} };
        @groups = @{ $privs->{groups} };
        @assets = @{ $privs->{assets} };
    }
    print {$log} "users : " . join(', ', @users) . "\n" if DEBUG;
    print {$log} "groups: " . join(', ', @groups) . "\n" if DEBUG;
    print {$log} "assets: " . join(', ', @assets) . "\n" if DEBUG;

    return 1
        if grep { $_ eq '1' } @users;
    print {$log} "visitor not granted access\n" if DEBUG;

    return 1
        if grep { $_ eq '1' || $_ eq '7' } @groups;
    print {$log} "Neither Everyone nor Visitors granted access\n" if DEBUG;

    my %cookies = CGI::Cookie->parse($cook);
   
    return
        unless @assets or $cookies{wgSession};
    print {$log} "Either we have assets to check or we have a session id\n" if DEBUG;

    my $sessionId;
    if ($cookies{wgSession}) {
        $sessionId = eval { $cookies{wgSession}->value };
        chomp $sessionId;
    }
    print {$log} "sessionId: $sessionId\n" if DEBUG;

    my $session = WebGUI::Session->open($root, $conf, undef, undef, $sessionId, 1);
    my $session_guard = Scope::Guard->new(sub { $session->close } );

    my $userId = $session->var->get('userId');

    print {$log} "userId: $userId\n" if DEBUG;

    return 1
        if grep { $_ eq $userId } @users;
    print {$log} "our userId not granted access\n" if DEBUG;

    my $user = $session->user;

    return 1
        if grep { $user->isInGroup($_) } @groups;
    print {$log} "our user not in allowed group\n" if DEBUG;
    
    for my $assetId ( @assets ) {
        my $asset       = WebGUI::Asset->new( $session, $assetId );
        return 1 if $asset && $asset->canView;
    }
 
    print {$log} "no assets allowing access\n" if DEBUG;

    return;
}

# reads lines from a file into an array, trimming white space and ignoring commented lines
sub readLines {
    my $file = shift;
    my @lines;
    if (open(my $fh, '<', $file)) {
        while (my $line = <$fh>) {
            $line =~ s/#.*//;
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
            next if !$line;
            push @lines, $line;
        }
        close $fh;
    }
    return @lines;
}



#!/usr/bin/perl -w

# usage: apt-get install perl;wget https://raw.github.com/plainblack/webgui/master/installwebgui -O | bash

=for comment

# SHELL STUFF TO GO FIRST:

# Debian packages: 
apt-get install perl

# cpanm
curl --insecure -L http://cpanmin.us | perl - App::cpanminus || exit 1

cpanm Curses Curses::Widgets

# so that we can probe mysql and such inside of a WRE... or should we be mutually exclusive with the WRE?
export PATH=/data/wre/prereqs/bin:/data/wre/prereqs/sbin:/data/wre/sbin:/data/wre/bin:$PATH
export LD_LIBRARY_PATH=/data/wre/prereqs/lib:$LD_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH=/data/wre/prereqs/lib:$DYLD_LIBRARY_PATH
export LD_RUN_PATH=/data/wre/prereqs/lib:$LD_RUN_PATH
export PERL5LIB=/data/wre/lib:/data/WebGUI/lib:$PERL5LIB


TODO:

* start script as a shell script then either unpack a perl script or self perk <<EOF it
* only thing to do while running as sh is to install perl, I think!

based in part on git://gist.github.com/2318748.git:
run on a clean debian stable
install webgui 8, using my little tweaks to get things going. 
xdanger

=cut

use strict;
use warnings;
no warnings 'redefine';

use Curses;
use Curses::Widgets;
use Curses::Widgets::TextField;
use Curses::Widgets::ButtonSet;
use Curses::Widgets::TextMemo;
use Curses::Widgets::ListBox;
use Curses::Widgets::Calendar;
use Curses::Widgets::ComboBox;
use Curses::Widgets::Menu;
use Curses::Widgets::Label;
use Curses::Widgets::ProgressBar;

use Carp;
# use IPC::Open3;

#
#
#

my $mwh = Curses->new;

noecho();
halfdelay(5);
$mwh->keypad(1);
$mwh->syncok(1);
curs_set(0);
leaveok(1);


sub main_win {

  # main window

  $mwh->erase();

  # This function selects a few common colours for the foreground colour
  $mwh->attrset(COLOR_PAIR(select_colour(qw(white black))));
  $mwh->box(ACS_VLINE, ACS_HLINE);
  $mwh->attrset(0);

  $mwh->standout();
  $mwh->addstr(0, 1, "WebGUI8");
  $mwh->standend();

}

main_win();


#
# comment box and progress bar is always on the screen but never in focus
#

my $progress = do {

    my ($y, $x);
    $mwh->getmaxyx($y, $x);

    Curses::Widgets::ProgressBar->new({
        Y           => $y - 15,
        X           => 1,
        MIN         => 0,
        MAX         => 100,
        LENGTH      => $x - 4,
        FOREGROUND  => 'white',
        BACKGROUND  => 'black',
        BORDER      => 1,
        BORDERCOL   => 'black',
        CAPTION     => 'Progress',
        CAPTIONCOL  => 'white',
    });
};

my $comment = do {
    my ($y, $x);
  
    # Get the main screen max y & X
    $mwh->getmaxyx($y, $x);
  
    Curses::Widgets::Label->new({
        CAPTION     => 'Comments',
        BORDER      => 1,
        LINES       => 8,
        COLUMNS     => $x - 4,
        Y           => $y - 12,
        X           => 1,
        # VALUE       => qq{ },
        FOREGROUND  => 'white',
        BACKGROUND  => 'black',
    });
};

#
#
#

sub update {
    my $message = shift;
    my $hop = shift;
    $message =~ s{^ +}{};
    $message =~ s{\n  +}{\n}g;
    $comment->setField( VALUE => $message ) if $message; 
    $comment->draw($mwh);
    $progress->input($hop) if $hop;
    $progress->draw($mwh);
}

sub bail {
    my $message = shift;
    update( $message );
    scankey($mwh);
    exit 1;
}

sub run {

    my $cmd = shift;
    my $noprompt = shift;

    my $msg = $comment->getField('VALUE');
    update( $msg . "\nRunning '$cmd'.\n" . ( defined $noprompt ? 'Hit Enter to continue or control-C to abort.' : '' ) );
    scankey($mwh) if ! defined $noprompt;

    open my $fh, '-|', "$cmd 2>&1" or bail(qq{
        $msg\nRunning '$cmd'\nFailed: $!
    });
    my $output = '';
    while( my $line = readline $fh ) { 
        $output .= $line; 
        update( $msg . "\n$cmd:\n$output" );
    }
    my $exit = close($output);

    #my $pid = open3( my $child_in, my $child_out, my $child_error, $cmd );
    #while( $output .= readline $child_out ) { }
    #while( $output .= readline $child_error ) { }  # not safe
    #waitpid $pid;
    #my $exit = close($output);

    if( $exit ) {
        bail( $msg . "\n$cmd:\n$output\nExit code $exit indicates failure.  Exiting." );
    } else {
        update( $msg . "\n$cmd:\n$output\nHit Enter to continue." );
        scankey($mwh);
        update( $msg );  # get rid of the extra stuff so that the next call to run() doesn't just keep adding stuff
    }

    $output;

}

update(qq{
    Welcome to the WebGUI8 installer utility!
    Press any reasonable key to begin or control-C to exit.
});

# $SIG{__DIE__} = sub { bail("Fatal error: $_[0]\n"); };
# $SIG{__DIE__} = sub { endwin(); print "\n" x 10; Carp::confess($_[0]); };
$SIG{__DIE__} = sub { bail("Fatal error: $_[0]" . Carp::longmess() ); };

scankey($mwh);

#
#
#

my $input_key = *Curses::Widgets::TextField::input_key{CODE};
*Curses::Widgets::TextField::input_key = sub {
    my $self = shift;
    my $key = shift;
    $key = KEY_BACKSPACE if ord($key) == 127;  # handle "delete" as "backspace"
    $input_key->($self, $key);
};

#
# some probes
#

# are we root?

my $root = $> == 0;

# which linux

my $linux = 'unknown';
$linux = 'debian' if -f '/etc/debian_version';
$linux = 'redhat' if -f '/etc/redhat-release';

#
# mysqld
#

my $safe_mysqld_path = `which mysqld_safe`; chomp $safe_mysqld_path if $safe_mysqld_path;

my $mysqld_path = `which mysqld`; chomp $mysqld_path if $mysqld_path;

if( $safe_mysqld_path and ! $mysqld_path ) {
    # mysqld is probably hiding in a libexec somewhere and mysqld_safe won't relay a request for --version
    # nevermind, we don't care about the version that much
}

my $mysqld_version;
if( $mysqld_path ) {
    my $extra = '';
    # if ! -x $mysqld_path # XXX
    update( $comment->getField('VALUE') . " Running command: $mysqld_path --version");
    my $sqld_version = `$mysqld_path --version`;
    # /usr/local/libexec/mysqld  Ver 5.1.46 for pc-linux-gnu on i686 (Source distribution)
    ($mysqld_version) = $mysqld_version =~ m/Ver (\d+\.\d+)\.\d+ for/ if $mysqld_version;
}

if( $safe_mysqld_path) {
    my $extra_text= '';
    $extra_text .= "MySQL installed at $mysqld_path is version $mysqld_version.\n" if $mysqld_path and $mysqld_version;
    update(qq{
        $extra_text
        Found mysqld_safe at $safe_mysqld_path.
        Using it.
        Hit enter to continue. 
    });
    scankey($mwh);
} else {
    if( ! $root ) {
        bail(qq{
            MySQL not found and root privileges are required to install it.
            Please hit any reasonable key to exit this script, then sudo to root and run it again.
        });
    } elsif( $linux eq 'debian' ) {
        update(qq{
            Installing Percona Server to satisfy MySQL dependency.
            This step adds the percona repo to your /etc/apt/sources.list (if it isn't there already) and then
            installs the packages percona-server-server-5.5 and libmysqlclient18-dev.
            Hit control-C to cancel or Enter to continue.
        });
        scankey($mwh);
        # percona mysql 5.5
        #apt-get update || exit 1
        # apt-get install percona-server-server-5.5 libmysqlclient18-dev 
        run( 'gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A' );
        run( 'sudo gpg -a --export CD2EFD2A | apt-key add -' );
        run( q{grep 'http://repo.percona.com/apt' /etc/apt/sources.list || echo "deb http://repo.percona.com/apt squeeze main" >> /etc/apt/sources.list} );
        run( 'apt-get update', 0 );
    } else {
        # XXX
        bail(qq{
            I don't yet know how to install MySQL or Percona on your system.  Please do so yourself using your package manager or
            installing it from source.
            Hit any key to exit.
        });
    }
}

#
# other system packages we need
#

do {
    if( $root ) {
        if( $linux eq 'debian' ) {
            run( 'apt-get install perlmagick libssl-dev libexpat1-dev git curl build-essential' );
        } else {
            update( "WebGUI needs the perlmagick libssl-dev libexpat1-dev git curl and build-essential modules but I don't yet know how to install them on your system; doing nothing, but you will need to make sure that this stuff is installed" );
            scankey($mwh);
        }
    } else {
        update( "WebGUI needs the perlmagick libssl-dev libexpat1-dev git curl and build-essential packages but I'm not running as root so I can't install them; please either install these or else run this script as root." );
        scankey($mwh);
    }
};

#
# /data directory
#

my $install_dir = '/data';

do {
    my $get_filename = Curses::Widgets::TextField->new({ 
        Y           => 4,
        X           => 1, 
        COLUMNS     => 60, 
        MAXLENGTH   => 80,
        FOREGROUND  => 'white',
        BACKGROUND  => 'black',
        VALUE       => $install_dir,
        BORDERCOL   => 'black',
        BORDER      => 1,
        CAPTION     => 'Install Directory',
        CAPTIONCOL  => 'white',
    });
  where_to_install:
    update(qq{
        Where do you want to install WebGUI8?
        The git repository will be checked out into a 'WebGUI' directory inside of there.
        The configuration files will be placed inside of 'WebGUI/etc' in there.
        Static and uploaded files for your site will be kept under in a 'domains' directory in there.
        Traditionally, WebGUI has lived inside of the '/data' directory, but this is not necessary.
    });
    $get_filename->draw($mwh);
    $get_filename->execute($mwh);
    $install_dir = $get_filename->getField('VALUE');
    update(qq{
        Create directory '$install_dir' to hold WebGUI?  [Y/N]
    });
    goto where_to_install unless scankey($mwh) =~ m/^y/i;
    main_win();  # erase the text dialogue
    update( qq{Creating directory '$install_dir'.\n} );
    run( "mkdir -p '$install_dir'", 0 );
    chdir $install_dir;
    mkdir 'extlib'; # XXX moved this up outside of 'WebGUI'
    $ENV{PERL5LIB} .= ":$install_dir/WebGUI/lib:$install_dir/extlib/lib/perl5";
};

#
# WebGUI git checkout
#

do {
    run(
        # https:// fails for me on a fresh Debian for want of CAs; use http:// or git://
        'git clone http://github.com/plainblack/webgui.git WebGUI'
    );
};

#
# fetch cpanm
#

do {
    run( 'curl --insecure --location http://cpanmin.us > WebGUI/sbin/cpanm', 0 );
    run( 'chmod ugo+x WebGUI/sbin/cpanm', 0 );
};

#
# testEnvironment.pl
#

do {
    my $test_environment_output = run( 'perl sbin/testEnvironment.pl' ); 
    # Checking for module Weather::Com::Finder:         OK
    my @results = grep m/Checking for module/, split m/\n/, $test_environment_output;
    for my $result ( @results ) {
        next unless $result ! =~ m/:.*OK/;
        $result =~ s{:.*}{};
        $result =~ s{Checking for module }{};
        run( "WebGUI/sbin/cpanm $result" );
    }

};

=for comment

# fix version number to match create.sql
# perl -p -i -e "s/8\.0\.1/8\.0\.0/g" lib/WebGUI.pm || exit 1 # XXXX let's see what happens if this doesn't run

# perl modules , the "-n" in the end means no tests are run, it's faster, but not safer
perl sbin/testEnvironment.pl --simpleReport | grep 'Checking for module'|grep -v 'Magick'| perl -ane 'print $F[3]. " "' | perl -pe 's/: / /g'|cpanm -n -L extlib

cp etc/WebGUI.conf.original etc/WebGUI.conf
cp etc/log.conf.original etc/log.conf

# get a working create.sql because someone messed up the one in repo
# sdw:  MySQL changed; there's no syntax that'll work with both new and old ones
perl -p -i -e "s/TYPE=InnoDB CHARSET=utf8/ENGINE=InnoDB DEFAULT CHARSET=utf8/g" share/create.sql
perl -p -i -e "s/TYPE=MyISAM CHARSET=utf8/ENGINE=MyISAM DEFAULT CHARSET=utf8/g" share/create.sql

mysql --password --user=root -e "create database www_example_com" || exit 1
mysql --password --user=root -e "grant all privileges on www_example_com.*  to webgui@localhost identified by 'password'" || exit 1
mysql --password=password --user=webgui www_example_com < share/create.sql || exit 1

#run webgui. -- For faster server install "cpanm -L extlib Starman" and add " -s Starman --workers 10 --disable-keepalive" to plackup command
export PERL5LIB=/data/WebGUI/lib:/data/WebGUI/extlib/lib/perl5
extlib/bin/plackup app.psgi

=cut



END {
  endwin();
}


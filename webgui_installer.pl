#!/usr/bin/perl -w

# usage: apt-get install perl;wget https://raw.github.com/plainblack/webgui/master/installwebgui -O | bash

=for comment

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2012 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

# SHELL STUFF TO GO FIRST:

# Debian packages: 
apt-get install perl sudo

# cpanm
curl --insecure -L http://cpanmin.us | perl - App::cpanminus || exit 1

cpanm Curses Curses::Widgets

# so that we can probe mysql and such inside of a WRE... or should we be mutually exclusive with the WRE?
export PATH=/data/wre/prereqs/bin:/data/wre/prereqs/sbin:/data/wre/sbin:/data/wre/bin:$PATH
export LD_LIBRARY_PATH=/data/wre/prereqs/lib:$LD_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH=/data/wre/prereqs/lib:$DYLD_LIBRARY_PATH
export LD_RUN_PATH=/data/wre/prereqs/lib:$LD_RUN_PATH
export PERL5LIB=/data/wre/lib:/data/WebGUI/lib:$PERL5LIB

XXX:

XXX Task::WebGUI
XXX Running upgrade script... Error upgrading www_example3_com.conf: Can't find upgrade path from 8.0.0 to 8.0.1.
XXX does it do "s" to skip this command reliably?
XXX test the sudo password when the user gives it and ask again if its wrong
XXX test the mysql password when the user gives it and ask again if its wrong
XXX mysql commands fail and it doesn't notice or care!?
XXX git clone WebGUI can fatal without consequence too
XXX error if a 'webgui' user already exists -- don't reset the password!
XXX several of the modules the script uses aren't stock, including Curses!
XXX /home/scott/bin/perl WebGUI/sbin/wgd reset --upgrade -- really not sure that's running and doing anything
XXX app.psgi should probably just do a 'use libs "extlib"' so that the user doesn't have to set up the local lib

TODO:

* start script as a shell script then either unpack a perl script or self perk <<EOF it
* only thing to do while running as sh is to install perl, I think!  ack, that and Curses and various modules
* offer help for modules that won't install
* use WRE stuff to do config file instead?  depends on the wre.conf, hard-codes in the prereqs path, other things
* cross-reference this with my install instructions
* save/restore variables automatically since we're asking for so many things?  touch for passwords though
* nginx!
* if something fails, offer to report the output of the failed command and the config variables
* don't just automatically apt-get install perlmagick; handle system perl versus source install of perl scenarios
* take command line arg options for the various variables we ask the user so people can run this partially or non interactively
* rather than trying to do '2>&1' on the end of run() command lines, actually get IPC::Open3 and select() going
* use File::Path <--- this is what we'd use if MacOS9 or Windows were a supported installer target
* would be awesome if this could diagnose and repair common problems
* add webgui to the system startup!  I think there's something like this in the WRE
* handle log rotation... add something to cron to run a script?
* even without using the WRE library code, look for mysql and such things in $install_root/wre and use them if there?

based in part on git://gist.github.com/2318748.git:
run on a clean debian stable
install webgui 8, using my little tweaks to get things going. 
xdanger

=cut

use strict;
use warnings;
no warnings 'redefine';

use Config;

BEGIN {
    my $perl = $Config{perlpath};
    push @INC, sub {
        my $self = shift;
        my $module = shift;
        return if grep $module eq $_, 'attrs.pm', 'Tie/StdScalar.pm', 'HTML/TreeBuilder/XPath/Node.pm';
        $module =~ s{/}{::}g;  $module =~ s{\.pm$}{};  
        warn "installing $module"; 
        my @module = ($module);
        @module = qw(Event Coro::Event Coro) if $module[0] eq 'Coro';  # all three, in order  
        my $cpanm = `which cpanm`;
        chomp $cpanm;
        if( ! $cpanm ) { 
            system 'wget', 'http://cpanmin.us', '-O', 'cpanm';
            $cpanm = 'cpanm';
        }
        system $perl, $cpanm, @module;
        return 1;
    };
};

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

use WRE::Config;
use WRE::Site;

use Config::JSON; # no relation to Config

use Cwd;

use File::Copy 'cp';
use FileHandle;

use Template;


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
        Y           => $y - 16,
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
        LINES       => 10,
        COLUMNS     => $x - 4,
        Y           => $y - 13,
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
    my $message = shift() || '';
    $message =~ s{^\n}{};
    $message =~ s{^ +}{};
    $message =~ s{\n  +}{\n}g;
    $comment->setField( VALUE => $message ) if $message; 
    $comment->draw($mwh);
    $progress->draw($mwh);
}

sub progress {
    my $percent = shift;
    # $progress->input($hop) if $hop;
    $progress->setField( VALUE => $percent ) if $percent; 
    $progress->draw($mwh);
}

sub bail {
    my $message = shift;
    update( $message );
    scankey($mwh);
    exit 1;
}

sub tail {
    my $text = shift;
    my $num_lines = 8;
    my @lines = split m/\n/, $text;
    @lines = @lines[ - $num_lines ..  -1 ] if @lines > $num_lines; 
    return join "\n", @lines;
}

sub run {

    # runs shell commands; verifies command with the user; collects error messages and shows them to the user

    my $cmd = shift;
    my $noprompt = shift;  # this is getting unwieldy
    my $nofatal = shift;

    my $msg = $comment->getField('VALUE');

    if( ! defined $noprompt) {
        update( $msg . qq{\nRunning '$cmd'.\nHit Enter to continue, press "s" to skip this command, or control-C to abort the script.} );
        my $key = scankey($mwh);
        if( $key =~ m/s/i ) {
            update( $msg );  # restore original message from before we added stuff
            return;
        }
    } else {
        update( $msg . "\nRunning '$cmd'." );
    }

    open my $fh, '-|', "$cmd 2>&1" or bail(qq{
        $msg\nRunning '$cmd'\nFailed: $!
    });
    my $output = '';
    while( my $line = readline $fh ) { 
        $output .= $line; 
        # update( $msg . "\n$cmd:\n$output" );
        update( tail( $msg . "\n$cmd:\n$output" ) );
    }
    my $exit = close($output);

    #my $pid = open3( my $child_in, my $child_out, my $child_error, $cmd );
    #while( $output .= readline $child_out ) { }
    #while( $output .= readline $child_error ) { }  # not safe
    #waitpid $pid;
    #my $exit = close($output);

    if( $exit and ! defined $nofatal ) {
        # XXX generate a failure report email in this case?
        bail $msg . "\n$cmd:\n$output\nExit code $exit indicates failure.  Exiting." ;
    } elsif( $exit and defined $nofatal ) {
        update( tail( $msg . "\n$cmd:\n$output\nExit code $exit indicates failure.\nHit Enter to continue." ) );
        scankey($mwh);
        update( $msg );  # get rid of the extra stuff so that the next call to run() doesn't just keep adding stuff
        return;
    } else {
        $output ||= 'Success.';
        update( tail( $msg . "\n$cmd:\n$output\nHit Enter to continue." ) );
        scankey($mwh);
        update( $msg );  # get rid of the extra stuff so that the next call to run() doesn't just keep adding stuff
    }

    $output;

}

sub text {
    my $title = shift;
    my $value = shift;
    my $text = Curses::Widgets::TextField->new({ 
        Y           => 4,
        X           => 1, 
        COLUMNS     => 60, 
        MAXLENGTH   => 80,
        FOREGROUND  => 'white',
        BACKGROUND  => 'black',
        VALUE       => $value,
        BORDERCOL   => 'black',
        BORDER      => 1,
        CAPTION     => $title,
        CAPTIONCOL  => 'white',
    });
    $text->draw($mwh);
    $text->execute($mwh);
    main_win();  # erase the text dialogue
    update();    # redraw after erasing the text dialogue
    return $text->getField('VALUE');
}

#
#
#

my $verbosity = 1;

do {
    update(qq{
        Welcome to the WebGUI8 installer utility!
        Currently Linux is supported and packages are automatically installed on Debian.
        You may press control-C at any time to exit.
        Examine commands before they're run to make sure that they're what you want to do!
        This script is provided without warranty, including warranty for merchantability, suitability for any purpose, and is not warrantied against special or incidental damages.  It may not work, and it may even break things.  Use at your own risk!  Always have good backups.  Consult the included source for full copyright and license.
        Press any reasonable key to begin.
    });
    scankey($mwh);

     update(qq{
         Do you want to skip questions that have pretty good defaults?
         You'll still be given a chance to inspect any potentially dangerous commands before they're run.
     });
     my $verbosiy_dialogue = Curses::Widgets::ListBox->new({
         Y           => 2,
         X           => 38,
         COLUMNS     => 20,
         LISTITEMS   => ['Fewer Questions', 'More Questions'],
         VALUE       => 0,
         SELECTEDCOL => 'white',
         CAPTION     => 'Detail Level',
         CAPTIONCOL  => 'white',
         FOCUSSWITCH => "\t\n",
     });
     $verbosiy_dialogue->draw($mwh);
     $verbosiy_dialogue->execute($mwh);
     $verbosity = $verbosiy_dialogue->getField('VALUE');
     main_win();  # erase the dialogue
     update();    # redraw after erasing the text dialogue
};
  


# $SIG{__DIE__} = sub { bail("Fatal error: $_[0]\n"); };
# $SIG{__DIE__} = sub { endwin(); print "\n" x 10; Carp::confess($_[0]); };
$SIG{__DIE__} = sub { bail("Fatal error: $_[0]" . Carp::longmess() ); };


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

my $starting_dir = getcwd;

#
# site name
#

my $site_name;
my $database_name;

do {
    update(qq{
        What domain name are you setting up this WebGUI for?
        The config file, database, and directory of uploaded files will be named after this.
        If you've already set up WebGUI and want to add another site, please instead use the addSite.pl utility.
        This doesn't matter much if you're only setting up one site for development.
        Most developers use "www.example.com" or "dev.localhost.localdomain".
    });
    $site_name = text( 'Domain name', 'www.example.com');
    ($database_name = $site_name) =~ s{\W}{_}g;
};

#
# /data directory
#

my $install_dir = $root ? '/data' : "$ENV{HOME}/webgui";

do {
  where_to_install:
    $install_dir = text("Install Directory", $install_dir);
    update(qq{
        Where do you want to install WebGUI8?
        Please enter an absolute path name (starting with a /).
        The git repository will be checked out into a 'WebGUI' directory inside of there.
        The configuration files will be placed inside of 'WebGUI/etc' in there.
        Static and uploaded files for your site will be kept under in a 'domains' directory in there.
        Traditionally, WebGUI has lived inside of the '/data' directory, but this is not necessary.
    });
    update(qq{
        Create directory '$install_dir' to hold WebGUI?  [Y/N]
    });
    goto where_to_install unless scankey($mwh) =~ m/^y/i;
    update( qq{Creating directory '$install_dir'.\n} );
    run( "mkdir -p '$install_dir'", 0 );
    chdir $install_dir;
    $ENV{PERL5LIB} .= ":$install_dir/WebGUI/lib:$install_dir/extlib/lib/perl5";
    $ENV{WEBGUI_ROOT} = "$install_dir/WebGUI";
    $ENV{WEBGUI_CONFIG} = "$install_dir/WebGUI/etc/$database_name.conf";
};

progress(5);

#
# sudo password
#

my $sudo_password;
my $sudo_command = '';

if( ! $root and `which sudo` ) {
    update( qq{
        If you like, enter your account password to use to sudo various commands.
        You'll be prompted before each command.
        You may also skip entering your password here and manually complete the steps that require root access in another terminal window.
    } );
    $sudo_password = text( qq{sudo password}, '' );
    $sudo_command = "echo $sudo_password | sudo -S "; # prepended to stuff that needs to run as root
} elsif( ! $root ) {
    update( qq{
        This script isn't running as root and I don't see sudo.
        You'll be prompted to run commands as root in another terminal window when and if needed.
        Hit Enter to continue.
    } );
    scankey($mwh);
};

progress(10);

#
# var and log dirs
#

my $log_files = '/tmp';
my $pid_files = '/var/run';

if( $verbosity >= 1 ) {
    # XXX should only ask this if some kind of a --verbose flag is on or if the user navigates here in a big menu of things to set

    update(qq{
        Into which directory should WebGUI and nginx write log files?
        Writing into /var/log requires starting up as root.
        WebGUI doesn't currently start as root and then drop privileges,
        so /tmp or $install_dir/var are probably the best options.
    });
    $log_files = text( 'Log File Directory', $log_files );

    update(qq{
        Into which directory should nginx write its PID file?
        Since nginx has to start up as root to listen on port 80 and knows how to drop privileges, /var/run is probably fine.
    });
    $pid_files = text( 'Log File Directory', $pid_files );
};

#
# port
#

my $webgui_port = 8081;

if( $verbosity >= 1 ) {

    # XXX the wG listen port should probably also be firewalled off from the outside world
    update(qq{
        nginx listens on port 80 (HTTP requests go there first) and handles serving static files.
        It proxies requests for dynamic content to WebGUI.
        Which port should WebGUI listen on?
        It should be higher than 1024 (so that WebGUI can start as a non-privileged user) and not already in use.
    });
    $webgui_port = text( 'WebGUI Listen Port', $webgui_port );

}

progress(15);

#
# mysqld
#

scan_for_mysqld:

my $mysqld_safe_path = `which mysqld_safe`; chomp $mysqld_safe_path if $mysqld_safe_path;

my $mysqld_path = `which mysqld`; chomp $mysqld_path if $mysqld_path;

if( $mysqld_safe_path and ! $mysqld_path ) {
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

my $mysql_root_password;
my $run_as_user = getpwuid($>);
my $current_user = $run_as_user;

if( $mysqld_safe_path) {

    # mysql already exists

    my $extra_text= '';
    $extra_text .= "MySQL installed at $mysqld_path is version $mysqld_version.\n" if $mysqld_path and $mysqld_version;
    update(qq{
        $extra_text
        Found mysqld_safe at $mysqld_safe_path.
        Using it.
        Hit enter to continue. 
    });
    scankey($mwh);

    update( qq{
        Please enter your MySQL root password.
        This will be used to create a new database to hold data for the WebGUI site, and to 
        create a user to associate with that database.
    } );
   $mysql_root_password = text('MySQL Root Password', '');

} else {

    # install and set up MySQL

    if( ( $root or $sudo_command ) and $linux eq 'debian' ) {
        update(qq{
            Installing Percona Server to satisfy MySQL dependency.
            This step adds the percona repo to your /etc/apt/sources.list (if it isn't there already) and then
            installs the packages percona-server-server-5.5 and libmysqlclient18-dev.
            Hit control-C to cancel or Enter to continue.
        });
        scankey($mwh);
        # percona mysql 5.5
        run( $sudo_command . 'gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A' );
        run( $sudo_command . 'gpg -a --export CD2EFD2A | apt-key add -' );
        if( ! `grep 'http://repo.percona.com/apt' /etc/apt/sources.list` ) {
            run( $sudo_command . qq{echo "deb http://repo.percona.com/apt squeeze main" >> /etc/apt/sources.list} );
        }
        run( $sudo_command . 'apt-get update', 0 );
        run( $sudo_command . 'apt-get install percona-server-server-5.5 libmysqlclient18-dev' ); 
    # XXXX
    # } elsif( $linux eq 'redhat' ) {
    #     rpm -Uhv http://www.percona.com/downloads/percona-release/percona-release-0.0-1.i386.rpm
    #     yum install -y Percona-Server-{server,client,shared,devel}-55
    } else {
        update(qq{
            MySQL/Percona not found.  Please use another terminal window (or control-Z this one) to install one of them, and then hit enter to continue.
        });
        scankey($mwh);
        goto scan_for_mysqld;
    }

    # user to run stuff as

    update( "Which user would you like to run mysqd as?\n" . ( $root ? "Since we're running as root, you may enter a new user name to create a new user." : "Since we're not running as root, if you enter a different user than the current one, I'll try to use sudo to launch mysqld as root so it can switch to that user." ) );
     # XXX add mysqld to the startup scripts
  pick_run_as_user:
    $run_as_user = text( "User to Run MySQL As", $run_as_user );
    if( $root and ! defined getpwnam( $run_as_user ) ) {
        update(qq{Creating user $run_as_user...});
        my $cmd = `which adduser` ? 'adduser' : `which useradd` ? 'useradd' : undef;
        defined $cmd or do {
            update( qq{
                I don't see either an 'adduser' nor a 'useradd' program.  
                Please add the user using whatever means are available to you and then enter their name here.
            } );
           goto pick_run_as_user;
        };
        run( "$cmd -s /sbin/nologin '$run_as_user'", 0 );
    } elsif( $root and ! defined getpwnam( $run_as_user ) ) {
        update(qq{
            User $run_as_user is not an existing user, but I'm not root so I can't create it for you.
            Please try again, or press control-C to exit.
        });
        scankey($mwh);
    }

    # database initialization

    run( qq{ mysql_install_db --user=$run_as_user } );

    # start mysql

    if( ( $root or $sudo_command ) and $run_as_user ne $current_user ) {
        update "Launching the new MySQL daemon...";
        run( qq{$sudo_command $mysqld_safe_path --user=$run_as_user & } ); # XXXX not sure that "echo | sudo &" is going to work
    } else {
        # run as the current user; that's easy!
        run( qq{ $mysqld_safe_path & }, 0, 0 ) or goto pick_run_as_user;
    }

    # set mysql root password

    update( qq{
        If MySQL was just installed, you'll probably want to set the MySQL 'root' user password.
        Would you like to set that password now?
    } );
    if( scankey($mwh) =~ m/^y/ ) {
        update( qq{ Please pick a MySQL root password. } );
        $mysql_root_password = text('MySQL Root Password', '');
        update( qq{ Setting MySQL root password. } );
        run( qq{mysql --user=root -e "SET PASSWORD FOR 'root' = PASSWORD('$mysql_root_password'); SET PASSWORD FOR 'root'\@'localhost' = PASSWORD('$mysql_root_password') SET PASSWORD FOR 'root'\@'127.0.0.1' = PASSWORD('$mysql_root_password');" } );
    }
     
    update( qq{ Deleing MySQL anonymous user. } );
    run( qq{mysql --user=root --password=$mysql_root_password -e "drop user '';" } );
}

progress(20);

#
# create database and user
#

my $mysql_user_password = join('', map { $_->[int rand scalar @$_] } (['a'..'z', 'A'..'Z', '0' .. '9']) x 12);

do {
    # XXX hard-coded database user name to 'webgui' for now and user has no say in what the password is
    update(qq{Creating database and database user.});
    run( qq{mysql --password=$mysql_root_password --user=root -e "create database $database_name"} );
    run( qq{mysql --password=$mysql_root_password --user=root -e "grant all privileges on $database_name.* to webgui\@localhost identified by '$mysql_user_password'"} );
};

progress(25);

#
# other system packages we need
#

do {
    if( $root or $sudo_command ) {
        if( $linux eq 'debian' ) {
            run( $sudo_command . 'apt-get update', 0 );
            run( $sudo_command . 'apt-get install -y perlmagick libssl-dev libexpat1-dev git curl build-essential nginx' );
        } else {
            update( "WebGUI needs the perlmagick libssl-dev libexpat1-dev git curl and build-essential modules but I don't yet know how to install them on your system; doing nothing, but you will need to make sure that this stuff is installed" );
            scankey($mwh);
        }
    } else {
        update( "WebGUI needs the perlmagick libssl-dev libexpat1-dev git curl and build-essential packages but I'm not running as root so I can't install them; please either install these or else run this script as root." ); # XXXX
        scankey($mwh);
    }
};

progress(30);

#
# WebGUI git checkout
#

do {
    update("Checking out a copy of WebGUI from GitHub...");
    run(
        # https:// fails for me on a fresh Debian for want of CAs; use http:// or git://
        # 'git clone http://github.com/plainblack/webgui.git WebGUI' # XXXXXXXXXX
        'git clone /tmp/WebGUI WebGUI' # XXXXXXXXXXXX
    );
};

progress(40);

#
# fetch cpanm
#

do {
    # XXX if the first bit of this script is a .sh, this will become redundant
    update( "Installing the cpanm utility to use to install Perl modules..." );
    run( 'curl --insecure --location --silent http://cpanmin.us > WebGUI/sbin/cpanm', 0 );
    run( 'chmod ugo+x WebGUI/sbin/cpanm', 0 );
};

progress(45);

#
# wgd
#

do {
    update( "Installing the wgd (WebGUI Developer) utility to use to run upgrades..." );
    run( 'curl --insecure --location --silent http://haarg.org/wgd > WebGUI/sbin/wgd', 0 );
    run( 'chmod ugo+x WebGUI/sbin/wgd', 0 );
};

progress(50);

#
# testEnvironment.pl
#

do {
    update( "Checking for needed Perl modules..." );
    my $test_environment_output = run( "$Config{perlpath} WebGUI/sbin/testEnvironment.pl" ); 
    # Checking for module Weather::Com::Finder:         OK
    my @results = grep m/Checking for module/, split m/\n/, $test_environment_output;
    for my $result ( @results ) {
        next if $result =~ m/:.*OK/;
        $result =~ s{:\s+.*}{};
        $result =~ s{Checking for module }{};
        update( "Installing Perl module $result from CPAN:" );
        if( $root or $sudo_command or -w $Config{sitelib_stem} ) {
            # if it's a perlbrew perl and the libs directory is writable by this user, or we're root, or we have sudo, just
            # install the module stright into the site lib.
            run( "$sudo_command $Config{perlpath} WebGUI/sbin/cpanm -n $result", 0 );
        } else {
            # backup plan is to build an extlib directory
            mkdir "$install_dir/extlib"; # XXX moved this up outside of 'WebGUI'
            run( "$Config{perlpath} WebGUI/sbin/cpanm -n -L $install_dir/extlib $result", 0 );
        }
    }

};

progress(60);

#
# create.sql syntax
#

if( $mysqld_version and $mysqld_version >= 5.5 ) {
    # XXX what is the actual cut off point?  is it 5.5, or something else?
    # get a working create.sql because someone messed up the one in repo
    # sdw:  MySQL changed; there's no syntax that'll work with both new and old ones
    update( 'Updating details in the create.sql to make MySQL/Percona >= 5.5 happy...' );
    run( $Config{perlpath} . ' -p -i -e "s/TYPE=InnoDB CHARSET=utf8/ENGINE=InnoDB DEFAULT CHARSET=utf8/g" share/create.sql ', 0);
    run( $Config{perlpath} . ' -p -i -e "s/TYPE=MyISAM CHARSET=utf8/ENGINE=MyISAM DEFAULT CHARSET=utf8/g" share/create.sql ', 0);
};

progress(65);

#
# create database and load create.sql
#

do {
    update( qq{
        Loading the initial WebGUI database.
        This contains configuration, table structure for all of the tables, definitions for the default assets, and other stuff.
    } );
    run( qq{ mysql --password=$mysql_user_password --user=webgui $database_name < WebGUI/share/create.sql } );
};

#
# WebGUI config files
#

do {
    # largely adapted from /data/wre/sbin/wresetup.pl
    cp 'WebGUI/etc/WebGUI.conf.original', "WebGUI/etc/$database_name.conf" or bail "Failed to copy WebGUI/etc/WebGUI.conf.original to WebGUI/etc/$database_name.conf: $!";
    cp 'WebGUI/etc/log.conf.original', 'WebGUI/etc/log.conf' or bail "Failed to copy WebGUI/etc/log.conf.original to WebGUI/etc/log.conf: $!";
    my $config = Config::JSON->new( "WebGUI/etc/$database_name.conf" );
    $config->set( dbuser          => 'webgui', );
    $config->set( dbpass          => $mysql_user_password, );
    $config->set( dsn             => "DBI:mysql:${database_name};host=127.0.0.1;port=3306" ); # XXX faster if we use the mysql.sock?
    $config->set( uploadsPath     => "$install_dir/domains/$site_name/public/uploads", );
    $config->set( extrasPath      => "$install_dir/domains/$site_name/public/extras", );
    $config->set( maintenancePage =>  "$install_dir/WebGUI/www/maintenance.html", );
    # XXX the searchIndexPlugins scripts that come with the WRE
};

progress(70);

#
# create webroot
#

do {
    # create webroot
    update qq{Creating site directory structure under $install_dir/domains/$site_name... };
    mkdir "$install_dir/domains" or bail "Couldn't create $install_dir/domains: $!";
    mkdir "$install_dir/domains/$site_name" or bail "Couldn't create $install_dir/domains/$site_name: $!";
    # mkdir "$install_dir/domains/$site_name/logs" or bail "Couldn't create $install_dir/domains/$site_name/logs: $!"; # not under /data/wre but instead in WebGUI and we let the user pick a dir earlier on
    mkdir "$install_dir/domains/$site_name/public" or bail "Couldn't create $install_dir/domains/$site_name/public: $!";
    mkdir "$install_dir/domains/$site_name/public/uploads" or bail "Couldn't create $install_dir/domains/$site_name/public/uploads: $!";
    update qq{Populating $install_dir/domains/$site_name/public/extras with bundled static HTML, JS, and CSS... };
    run "$Config{perlpath} WebGUI/sbin/wgd reset --uploads", 0;
};

progress(75);

#
# nginx config
#

do {
# XXXXXX testing
    # create nginx config

    update "Setting up nginx main config";
    eval { 
        template("$starting_dir/setupfiles/nginx.conf", "$install_dir/nginx.conf", { } ) 
    } or bail "Failed to template $starting_dir/setupfiles/nginx.conf to $install_dir/nginx.conf: $@";

    update "Setting up nginx per-site config";
    # addsite.pl does this as a two-step process
    # $file->copy($config->getRoot("/var/setupfiles/nginx.template"), $config->getRoot("/var/nginx.template"), { force => 1 });
    # $file->copy($wreConfig->getRoot("/var/nginx.template"), $wreConfig->getRoot("/etc/".$sitename.".nginx"), { templateVars => $params, force => 1 });
    # XXX we're putting $sitename.nginx in WebGUI/etc, not wre/etc; probably have to change the main nginx.conf to match; yup, testing
    eval { 
        template("$starting_dir/setupfiles/nginx.template", "$install_dir/WebGUI/etc/$database_name.nginx", { } ) 
    } or bail "Failed to template $starting_dir/setupfiles/nginx.template to $install_dir/WebGUI/etc/$database_name.nginx: $@";

    update "Setting up mime.types file";
    cp "$starting_dir/setupfiles/mime.types", "$install_dir/WebGUI/etc/mime.types" or 
        bail "Failed to copy $starting_dir/setupfiles/nginx.template to $install_dir/WebGUI/etc/$database_name.nginx: $@";
};

progress(80);

#
# miserable hack
#

do {
    # fix version number to match create.sql
    update( qq{
        Working around a release problem where upgrades refuse to run because of a version mismatch.
    } );
    run( $Config{perlpath} . ' -p -i -e "s/8\.0\.1/8\.0\.0/g" WebGUI/lib/WebGUI.pm', 0 );
};



#
# upgrades
#

do {
    update( qq{
        Running upgrades.
        Each release of WebGUI includes upgrade scripts that modify the database or config files.
        However, a new config file and database dump are not included in each release, so upgrades 
        are necessary even for brand new installs.
    } );
    run( "$Config{perlpath} WebGUI/sbin/wgd reset --upgrade", 0 );
};

progress(90);

#
# parting comments
#

do {
    #run webgui. -- For faster server install "cpanm -L extlib Starman" and add " -s Starman --workers 10 --disable-keepalive" to plackup command

    # XXX should dynamically include a list of things the user needs to manually do
    update( qq{
        Installation is wrapping up.

        This script has not added MySQL/Percona to your system start up.  You'll need to do that.
        You'll also need to add a startup script to start WebGUI if want it to start with the system.

        Documentation and forums are at http://webgui.org.
    } );
    scankey($mwh);

    open my $fh, '>', "$install_dir/webgui.sh";
    $fh->print(<<EOF);
cd $install_dir/WebGUI
export PERL5LIB="\$PERL5LIB:/$install_dir/WebGUI/lib"
export PERL5LIB="\$PERL5LIB:/$install_dir/extlib/lib/perl5" # needed if Perl modules were installed without write permission to the site lib
export PATH="$install_dir/extlib/bin/:\$PATH"  # needed if Starman was installed without write permission to install in the site lib
plackup --port $webgui_port app.psgi &
nginx /$install_dir/nginx.conf &
EOF
    close $fh;
     
    percent(100);

    update( qq{
        Installation complete.
        Please see $install_dir/webgui.sh for an example of starting up WebGUI.
        If cpanm was able to install modules into the siteperl directory, this should work:

        cd $install_dir/WebGUI
        export PERL5LIB="/$install_dir/WebGUI/lib"
        plackup --port $webgui_port app.psgi

        Please hit any reasonable key to exit the installer.
    } );
    scankey($mwh);

};

#
# goo
#

sub template {
    my $infn = shift;
    my $outfn = shift;
    my $var = shift;

    # $var->{config}      =  $config; # XXXX change references or else mock up an object
    # $var->{wreRoot}     = $config->getRoot; # doesn't seem to actually be used in the installfiles templates; however, config.getRoot is used and I think is the same thing, which is problematic
    $var->{webgui_root}   = "$install_dir/WebGUI/";  # also doesn't seem to actually be used in the installfiles templates
    $var->{domainRoot}    = "$install_dir/domains/";  # this one is used
    $var->{osName}        = ($^O =~ /MSWin32/i || $^O=~ /^Win/i) ?  "windows" : $^O;
    $var->{sitename}      =  $site_name; 
    $var->{domain} =  $site_name;  $var->{domain} =~ s/[^.]+\.//;
    $var->{domain_name_has_www} = $site_name =~ m/^www\./;
    $var->{run_as_user}   = $run_as_user;
    $var->{pid_files}     = $pid_files;
    $var->{log_files}     = $log_files;
    $var->{webgui_port}   = $webgui_port;

    open my $infh, '<', $infn or die "Couldn't open $infn: $!";
    read $infh, my $input, -s $infh;
    close $infh or die $!;

    open my $outfh, '>', $outfn or die "Couldn't open $outfn: $!";

    my $template = Template->new(INCLUDE_PATH=>'/');
    $template->process(\$input, $var, \my $output) or die $template->error;

    print $outfh $output or die $!;
    close $outfh or die $!;
}

END {
  endwin();
}


#!/usr/bin/perl -w

# usage: apt-get install perl;wget https://raw.github.com/plainblack/webgui/master/installwebgui -O | bash

=for comment

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


TODO:

* start script as a shell script then either unpack a perl script or self perk <<EOF it
* only thing to do while running as sh is to install perl, I think!
* offer help for modules that won't install
* don't just run 'perl'; use the perl that was used to run this script!
* use WRE stuff to do config file instead?
* cross-reference this with my install instructions
* run() should maybe have an "press enter or hit 's' to skip" feature built in, where all non-noprompt commands are optional
* save/restore variables automatically since we're asking for so many things?  touch for passwords though

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
    my $message = shift() || '';
    my $hop = shift;
    $message =~ s{^\n}{};
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
        update( $msg . "\n$cmd:\n$output" );
    }
    my $exit = close($output);

    #my $pid = open3( my $child_in, my $child_out, my $child_error, $cmd );
    #while( $output .= readline $child_out ) { }
    #while( $output .= readline $child_error ) { }  # not safe
    #waitpid $pid;
    #my $exit = close($output);

    if( $exit and ! defined $nofatal ) {
        bail( $msg . "\n$cmd:\n$output\nExit code $exit indicates failure.  Exiting." );
    } elsif( $exit and defined $nofatal ) {
        status( $msg . "\n$cmd:\n$output\nExit code $exit indicates failure.\nHit Enter to continue." );
        scankey($mwh);
        update( $msg );  # get rid of the extra stuff so that the next call to run() doesn't just keep adding stuff
        return undef;
    } else {
        update( $msg . "\n$cmd:\n$output\nHit Enter to continue." );
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

update(qq{
    Welcome to the WebGUI8 installer utility!
    You may press control-C at any time to exit.
    Examine commands before they're run to make sure that they're what you want to do!
    This script is provided without warranty, including warranty for merchantability, suitability for any purpose, and is not warrantied against special or incidental damages.  It may not work, and it may even break things.  Use at your own risk!  Always have good backups.  Consult the included source for full copyright and license.
    Press any reasonable key to begin.
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
    ($database_name = $site_name) =~ s{\.}{_}g;
};

#
# mysqld
#

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
        run( 'gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A' );
        run( 'sudo gpg -a --export CD2EFD2A | apt-key add -' );
        run( q{grep 'http://repo.percona.com/apt' /etc/apt/sources.list || echo "deb http://repo.percona.com/apt squeeze main" >> /etc/apt/sources.list} );
        run( 'apt-get update', 0 );
        run( 'apt-get install percona-server-server-5.5 libmysqlclient18-dev' ); 
    } else {
        # XXX
        bail(qq{
            I don't yet know how to install MySQL or Percona on your system.  Please do so yourself using your package manager or
            installing it from source.
            Hit any key to exit.
        });
    }

    # user to run stuff as

    update( "Which user would you like to run mysqd as?\n" . ( $root ? "Since we're running as root, you may enter a new user name to create a new user." : "Since we're not running as root, if you enter a different user than the current one, I'll try to use sudo to launch mysqld as root so it can switch to that user." ) );
     # XXXX either add mysqld to the startup scripts or else tell the user that we aren't and that they need to do it theirself
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

    if( $root and $run_as_user ne $current_user ) {
        update( "Launching the new MySQL daemon..." );
        run( qq{ $mysqld_safe_path --user=$run_as_user & } );
    } elsif( $run_as_user ne $current_user ) {
        update( qq{
            Launching the new MySQL daemon. 
            Please enter your password for sudo so that mysqld_safe can switch from root to the specified user.
        } );
        my $password = text( qq{sudo password}, '' ); # XXX do this early and re-use it as needed; add logic to run() to sudo as necessary
        run( qq{ echo $password | sudo -S $mysqld_safe_path --user=$run_as_user & } );
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


#
# create.sql syntax
#

if( $mysqld_version and $mysqld_version >= 5.5 ) {
    # XXX what is the actual cut off point?  is it 5.5, or something else?
    # get a working create.sql because someone messed up the one in repo
    # sdw:  MySQL changed; there's no syntax that'll work with both new and old ones
    update( 'Updating details in the create.sql to make MySQL/Percona >= 5.5 happy...' );
    run(' perl -p -i -e "s/TYPE=InnoDB CHARSET=utf8/ENGINE=InnoDB DEFAULT CHARSET=utf8/g" share/create.sql ', 0);
    run(' perl -p -i -e "s/TYPE=MyISAM CHARSET=utf8/ENGINE=MyISAM DEFAULT CHARSET=utf8/g" share/create.sql ', 0);
};

#
# create database and load create.sql
#

do {
    update( qq{
        Loading the initial WebGUI database.
        This contains configuration, table structure for all of the tables, definitions for the default assets, and other stuff.
    } );
    run( qq{ mysql --password=$mysql_user_password --user=webgui $database_name < share/create.sql } );
};

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
        update( "WebGUI needs the perlmagick libssl-dev libexpat1-dev git curl and build-essential packages but I'm not running as root so I can't install them; please either install these or else run this script as root." ); # XXXX
        scankey($mwh);
    }
};

#
# /data directory
#

my $install_dir = '/data';

do {
    #my $get_filename = Curses::Widgets::TextField->new({ 
    #    Y           => 4,
    #    X           => 1, 
    #    COLUMNS     => 60, 
    #    MAXLENGTH   => 80,
    #    FOREGROUND  => 'white',
    #    BACKGROUND  => 'black',
    #    VALUE       => $install_dir,
    #    BORDERCOL   => 'black',
    #    BORDER      => 1,
    #    CAPTION     => 'Install Directory',
    #    CAPTIONCOL  => 'white',
    #});
    $install_dir = text("Install Directory", $install_dir);
  where_to_install:
    update(qq{
        Where do you want to install WebGUI8?
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
    mkdir 'extlib'; # XXX moved this up outside of 'WebGUI'
    $ENV{PERL5LIB} .= ":$install_dir/WebGUI/lib:$install_dir/extlib/lib/perl5";
};

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

#
# fetch cpanm
#

do {
    update( "Installing the cpanm utility to use to install Perl modules..." );
    run( 'curl --insecure --location http://cpanmin.us > WebGUI/sbin/cpanm', 0 );
    run( 'chmod ugo+x WebGUI/sbin/cpanm', 0 );
};

#
# testEnvironment.pl
#

do {
    update( "Checking for needed Perl modules..." );
    my $test_environment_output = run( 'perl sbin/testEnvironment.pl' ); 
    # Checking for module Weather::Com::Finder:         OK
    my @results = grep m/Checking for module/, split m/\n/, $test_environment_output;
    for my $result ( @results ) {
        next if $result =~ m/:.*OK/;
        $result =~ s{:.*}{};
        $result =~ s{Checking for module }{};
        update( "Installing Perl module $result from CPAN:" );
        run( "WebGUI/sbin/cpanm -n -L extlib $result" );
    }

};

#
# config files
#

=for comment

TODO:

# fix version number to match create.sql
# perl -p -i -e "s/8\.0\.1/8\.0\.0/g" lib/WebGUI.pm || exit 1 # XXXX let's see what happens if this doesn't run

# XXX need more than this; use the WRE addsite stuff
    /data/wre/sbin/wresetup.pl
cp etc/WebGUI.conf.original etc/WebGUI.conf
cp etc/log.conf.original etc/log.conf

   $ wget http://haarg.org/wgd -O wgd
   $ sudo chmod ugo+x wgd
   $ sudo mv wgd /data/wre/prereqs/bin/

  $ wgd reset --upgrade

#run webgui. -- For faster server install "cpanm -L extlib Starman" and add " -s Starman --workers 10 --disable-keepalive" to plackup command
export PERL5LIB=/data/WebGUI/lib:/data/WebGUI/extlib/lib/perl5
extlib/bin/plackup app.psgi

=cut



END {
  endwin();
}


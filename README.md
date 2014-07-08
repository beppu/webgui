
# The WebGUI8 Content Management System

## About

WebGUI is a mature, feature rich Content Management System.  It's written in Perl and licensed under the GNU GPL.  Some features include:

* Hierarchical permissions
* Groups of groups of groups (etc)
* Asset versioning
* A workflow builder that can do things like require two Content Managers to give approval before user submitted content goes online
* Selectable workflows for new/edited assets
* Assets create other assets; almost everything is an asset
* Easily, cleanly extensible OO architecture
* Discussion boards, shops, image galleries, ticket trackers, and various other types of interactive content
* Scalable architecture suitable for busy sites

## Installation

This assumes that your site is "www.example.com".  If it's something else, change the commands to match.

* Load share/create.sql into your MySQL/MariaDB/Percona
* Run testEnvironment.pl to install all new requirements
* Get a new wgd, the wG command line tool, from http://haarg.org/wgd
* Copy etc/WebGUI.conf.original to www.whatever.com.conf
* Edit the conf file and set dbuser, dbpass, dsn, uploadsPath (eg to /data/domains/www.example.com/public/uploads/), extrasPath, maintenancePage and siteName
* Set WEBGUI_CONFIG to point at your new config file
* Run upgrades (yes, even for brand new install):  wgd reset --upgrade
* Copy the "extras" directory from whereever you unpacked it to whereever you pointed extrasPath to in the config file.  For example, if you unpacked the source in /data/WebGUI and the extrasPath to /data/domains/www.example.com/public/, you'd run: rsync -r -a /data/WebGUI/www/extras /data/domains/www.example.com/public/

## To start WebGUI

To test or develop:

* Set the PERL5LIB environment variable:  export PERL5LIB='/data/WebGUI/lib'
* Launch it:   plackup app.psgi

See docs/install.txt for more detailed installation instructions.

A production site or a dev site that tests sending email or workflows will also need the spectre daemon running.

A proxy server such as nginx or Apache configured to proxy is highly recommended for production sites.
The proxy server should serve /extras and /uploads and pass everything else to the plack server process.
See docs/install.txt for a recommended plack configuration for production.

## The Request Cycle

* The root level app.psgi file loads all the config files found and loads the site specific psgi file for each, linking them to the proper host names.
* The site psgi file uses the WEBGUI_CONFIG environment variable to find the config.
* It instantiates the $wg WebGUI object (one per app).
* $wg creates and stores the WebGUI::Config (one per app)
* $wg creates the $app PSGI app code ref (one per app)
* WebGUI::Middleware::Session is wrapped around $app at the outer-most layer so that it can open and close the $session WebGUI::Session. Any other wG middleware that needs $session should go in between it and $app ($session created one per request)
* $session creates the $request WebGUI::Session::Request and $response WebGUI::Session::Response objects (one per request)
* lib/WebGUI.pm does basic dispatch, first checking for a content handler, and then as a last resort (but the usual case), defaulting to the asset content handler
* The content handlers are configured in the .conf file
* The asset content handler, lib/WebGUI/Content/Asset.pm, looks up the asset by URL in the database

## Community Process

We welcome contributions, and there are plenty of ways to help.

* Install wG8, test it or just try to use it, and report bugs at http://www.webgui.org/8
* Hop on #webgui on FreeNode IRC using your favorite IRC-enabled chat client (or see irc.orgfor more info) to chat
* Help update the Wiki at http://webgui.org/wiki
* Fork http://github.com/plainblack/webgui (official version) or http://github.com/scrottie/webgui (experimental/unofficial/recommended development repo), make changes in master or in a branch, commit them, push them up, and then use github to send a "pull request"
* Contribute code and get access to commit directly to http://github.com/scrottie/webgui

Here are some specific tasks to be done:

* Develop a good looking community development process site perhaps similar in style to https://powerbulletin.com/ to be hosted on github pages
* Merge in Haarg's work on replacing ImageMagick with something that installs reliably 
* Track down the WordPress->wG convertion utility, document the state of it, and add it to the project; one ex-PlainBlack employee started it and the code should be on github somewhere
* Merge in the experimental installer from https://gist.github.com/scrottie/2973558 and update the documentation to suggest using it
* Create a new, modern theme; documentation for doing this is in the _WebGUI Designers Guide_ at https://www.webgui.org/documentation2/webgui-designers-guide


package WebGUI::Macro::WidgetFactory;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Asset::Template;

=head1 NAME

Package WebGUI::Macro::WidgetFactory

=head1 DESCRIPTION

Handy Macro to create WebWidgets, it can take the difficulty out of ...

=head2 process( $session, widget, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item *

A session variable

=item *

Any other options that were sent to the macro by the user.  It is up to you to set defaults and
to validate user input.

=back

=cut

our $supportedWidgets = {
	datatable => { package => 'WebGUI::Form::DataTablesNet', parseConfigMethod => 'getDatatableConfig' }  
};

#-------------------------------------------------------------------
sub process {
   my $session = shift;
	my $widget = shift;
	
	if ( $supportedWidgets->{ $widget } ){
      # Get the method used to configure the widget
      my $widgetConfigMethod = \&{ $supportedWidgets->{ $widget }->{parseConfigMethod} };
		# Get the widget and return html to the user;
		my $currentInstance = $supportedWidgets->{ $widget }->{package}->new( $session, $widgetConfigMethod->( @_ ) );
		return $currentInstance->toHtml();
	
   }else{
		WebGUI::Error::InvalidParam->throw( error => qq{Unsuported widget: $widget} );
		
   }

}

sub getDatatableConfig {
	my @tableConfig =  @_;
	
	my $config = {};
	my $foundRawConfig = undef;	
	my $columnConfig = [];
	my $configSettings = [];
	while( my $option = shift( @tableConfig ) ){
		my $strippedOption = WebGUI::HTML::filter( $option, 'all' );
		if ( $strippedOption =~ m/config:/ ){
		   $foundRawConfig = 1;
			$config->{config} = createHashRef( $strippedOption )->{config};
			
		}else{
		   if ( $foundRawConfig ){
            $config->{config} .= $strippedOption;
			}else{
		      if( $strippedOption =~ m/column:/ ){
					 push( @{ $columnConfig }, createHashRef( $strippedOption ) );
				}else{
					 push(@{ $configSettings }, createHashRef( $strippedOption ) );
				}
			}
		}
	}
	
   $config->{columnConfig} = $columnConfig;
	
   foreach my $singleConfig ( @{ $configSettings } ){
      for my $key ( keys( %{ $singleConfig } ) ){
         $config->{ $key } = $singleConfig->{ $key };
      }
   }		  
		  
#   my $columnConfig = [
#     { column => "userId",       title => "UserId" },
#     { column => "lastIP",       title => "Last Ip" },
#     { column => "lastPageView", title => "Last View" },
#     { column => "username",     title => "Username" },
#     { column => "expires",      title => "Expires" },
#	  { column => "sessionId",    title => "Kill Session", checkbox => "1", cssClass => "killSession", name => 'killSession' }
#   ];
	
   #my $datatable = WebGUI::Form::DataTablesNet->new(
   #   $session, { config => $rawConfig, columnConfig => $columnConfig, noScript => 1, restDataUrl => "/?op=viewActiveSessions", id => "sessionsDatatable" }
   #);
   
	return $config;

}

sub createHashRef{
	 my $rawData = shift;
    $rawData =~ s/\{//g;
    $rawData =~ s/\}//g;
    my @options = split(';', $rawData);
    my $usableData = {};
    foreach my $option ( @options ){
        $option =~ s/'//g;
    	  my ( $key, $value ) = split(':', $option);
    	  $usableData->{ $key } = $value;
    }
	 return $usableData;
}

1;

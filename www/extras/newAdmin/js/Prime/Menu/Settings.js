define(['jquery','jqueryui','Prime'],function($, ui, Prime){
    return function() {
      //var settingsDatatable, groupDatatable, loginHistoryDatatable; // Make sure we can reference these objects in the code below
       
      // adminOverlayContent is defined in AdminMenu.js
      $('#adminOverlayContent').tabs(); // Make sure the tabs are rendered if we have any
       
      // what happens when we click the tab
      $('.adminOverlayTabs-click').click(function(event) {
         var operation = $(event.target).attr('target');
alert("XXX Settings.js operation = " + operation);
       
         if ( operation === 'op=editSettings' ) {
       
            require(['Prime/Menu/Settings/Settings'],function(settings){
               settings();
            });
       
         // ... more here
       
         } else {
            // XXX sdw: as I understand this, it'll take '#settingsTarget' from the <a class="adminOverlayTabs-click" href="#settingsTarget"> and use that value
            // as the selector that load() loads into; but what really happens is the browser is sent to the url #settingsTarget in a new window
            var target = $(event.target).attr('href');
alert("XXX Settings.js punting to " + Prime.config().jsonSourceServer + '?' + operation );
            $( target ).load( Prime.config().jsonSourceServer + '?' + operation , function(response, status, xhr) {
               if (status === 'error') {
                  $('#message').html( response.message );
               }
            });
         }
    
      });

    };

});

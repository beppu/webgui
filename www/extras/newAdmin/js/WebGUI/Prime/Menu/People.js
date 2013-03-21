define(['jquery','jqueryui','WebGUI/Prime'],function($, ui, Prime){
   return function(){
      //var sessionsDatatable, groupDatatable, loginHistoryDatatable; // Make sure we can reference these objects in the code below
      $('#adminOverlayContent').tabs(); // Make sure the tabs are rendered if we have any
      // what happens when we click the tab
      $('.adminOverlayTabs-click').click(function(event){
         var operation = $(event.target).attr('target');
         if ( operation === 'op=viewActiveSessions' ){
            require(['WebGUI/Prime/Menu/People/Sessions'],function(sessions){
               sessions();
            });
            
         }else if ( operation === 'op=listGroups' ){ 
            require(['WebGUI/Prime/Menu/People/Groups'],function(groups){
               groups();
            });

         }else if ( operation === 'op=viewLoginHistory' ){
            require(['WebGUI/Prime/Menu/People/LoginHistory'],function(loginHistory){
               loginHistory();
            });

         }else{
            var target = $(event.target).attr('href');
            $( target ).load( Prime.config().jsonSourceServer + '?' + operation , function(response, status, xhr) {
               if (status === 'error') {
                  $('#message').html( exception );
               }
            });
         }     

      });
   };
});

define(['jquery','jqueryui','Prime'],function($, ui, Prime){
   return function(){
      //var sessionsDatatable, groupDatatable, loginHistoryDatatable; // Make sure we can reference these objects in the code below
      $('#adminOverlayContent').tabs(); // Make sure the tabs are rendered if we have any
      // what happens when we click the tab
      $('.adminOverlayTabs-click').click(function(event){
         var operation = $(event.target).attr('target');
         if ( operation === 'op=viewActiveSessions' ){
            require(['Prime/Menu/People/Sessions'],function(sessions){
               sessions();
            });
            
         }else if ( operation === 'op=listGroups' ){ 
            require(['Prime/Menu/People/Groups'],function(groups){
               groups();
            });

         }else if ( operation === 'op=viewLoginHistory' ){
            require(['Prime/Menu/People/LoginHistory'],function(loginHistory){
               loginHistory();
            });

         }else if ( operation === 'op=listUsers' ){
            require(['Prime/Menu/People/Users'],function(users){
               users();
            });
            
         }else{
            var target = $(event.target).attr('href');
            $( target ).load( Prime.config().jsonSourceServer + '?' + operation , function(response, status, xhr) {
               if (status === 'error') {
                  $('#message').html( response.message );
               }
            });
         }     

      });
   };
});

define(['jquery','jqueryui','WebGUI/Prime','can'],function($, ui, Prime, can){
   return function(){
      //var sessionsDatatable, groupDatatable, loginHistoryDatatable; // Make sure we can reference these objects in the code below
      $('#adminOverlayContent').tabs(); // Make sure the tabs are rendered if we have any
      // what happens when we click the tab
      $('.adminOverlayTabs-click').click(function(event){
         var operation = $(event.target).attr('target');
         if ( operation === 'viewOtherHelp' ){          
            var jsonSource = Prime.config().otherHelp;
            $.getJSON(jsonSource, function(help){
                var template = Prime.config().template.path + 'otherHelp.ejs';
                $('#otherHelpContainer').html( can.view.render(template, help ) );
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
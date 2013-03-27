define(['WebGUI/Prime','WebGUI/Prime/Menu/People/UserList','jquery','jqueryui'],function(Prime, users){
   return function(){
      $('#usersContainer').html( can.view(Prime.config().template.path + 'people/users.ejs' ) );
      
      // display the users in the added table
      users('#usersDatatable', {op:"listUsers"} ).on('click', "a", function(event){
         event.preventDefault();
         var jsonPathFromTag = event['target']['href'];
         console.log( jsonPathFromTag ); 

      }); 
      
      //  toggle all users checkboxes
      $('#delete-all-users-toggle').click(function(){
         var master = $(this).is(':checked');
         $('#usersDatatable input.useridCheckbox').each(function(){ 
            $(this).prop('checked',master);
         });
      });      
      
            
      $('button#delete-users-button').button().click(function(event){
         event.preventDefault();
         var users = [];
         $('#usersDatatable input.useridCheckbox').each(function(){
            if ( $(this).is(':checked') ){
               users.push( $(this).attr('value') );
            }
         });
         
         console.log( users );
      });
   };
});
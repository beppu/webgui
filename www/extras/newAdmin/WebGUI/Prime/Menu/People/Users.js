define(['WebGUI/Prime','WebGUI/Prime/Menu/People/UserList','WebGUI/Prime/AjaxHelper','jquery','jqueryui'],function(Prime, users, AjaxHelper, $){
   return function(){
      var jsonPath = Prime.config().jsonSourceServer;
      $('#usersContainer').html( can.view(Prime.config().template.path + 'people/users.ejs' ) );
      
      // display the users in the added table
      var userDatatable = users('#usersDatatable', {op:"listUsers"} ).on('click', "a", function(event){
         event.preventDefault();
         var jsonPathFromTag = event['target']['href'];// edit the user
         console.log( jsonPathFromTag ); 

      }); 
      
      //  toggle all users checkboxes
      $('#delete-all-users-toggle').click(function(){
         var master = $(this).is(':checked');
         $('#usersDatatable input.useridCheckbox').each(function(){ 
            $(this).prop('checked',master);
         });
      });   

      // Add users
      $('button#add-users-button').button().click(function(event){
         event.preventDefault();
         require(['WebGUI/Prime/Menu/People/AddUser'],function(addUser){
            addUser();
         });

      });      
      
      // Delete selected users
      $('button#delete-users-button').button().click(function(event){
         event.preventDefault();
         var users = [];
         $('#usersDatatable input.useridCheckbox').each(function(){
            if ( $(this).is(':checked') ){
               users.push( $(this).attr('value') );
            }
         });
         
         if ( users.length > 0 ){
            $( "#dialog-delete-confirm" ).dialog({
               modal: true,
               buttons: {
                  "Delete all items":function(){
                     var jsonSubmit = jsonPath + '?op=deleteUsers&ids=' + users;
                     AjaxHelper({ jsonPath: jsonSubmit });
                     userDatatable.fnDraw();// refresh the table once I remove the session
                     $( this ).dialog( "close" );
                  },
                  Cancel: function() {
                     $( this ).dialog( "close" );
                  }
               }
            });
         }

      });
   };
});
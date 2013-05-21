define(['Prime','Prime/Menu/People/UserList','Prime/AjaxHelper','jquery','jqueryui'],function(Prime, users, AjaxHelper, $){
   return function(){
      var jsonPath = Prime.config().jsonSourceServer;
      $('#usersContainer').html( can.view(Prime.config().template.path + 'people/users.ejs' ) );
      
      // Show the controls if not shown at this point
      $('div.user-add-delete-controls').show();
      
      // display the users in the added table
      var userDatatable = users('#usersDatatable').on('click', "a", function(event){
         event.preventDefault();
         var userid = event['target']['href'];// edit the user
         require(['Prime/Menu/People/AddUser'],function(editUser){
            editUser(userid);
            
         });         

      }); 
      
      //  toggle all users checkboxes
      $('#delete-all-users-toggle').click(function(){
         var master = $(this).is(':checked');
         $('#usersDatatable input.useridCheckbox').each(function(){ 
            $(this).prop('checked',master);
         });
      });   

      // Add users
      $('button#add-users-button').show().button().click(function(event){
         event.preventDefault();
         require(['Prime/Menu/People/AddUser'],function(addUser){
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
                     AjaxHelper({ jsonPath: jsonSubmit, callback:function(){ userDatatable.fnDraw(); } }); //::TODO:: may have to do the datatable refresh after this line.
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
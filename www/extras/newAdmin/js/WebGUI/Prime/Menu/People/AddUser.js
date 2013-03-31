define(['WebGUI/Prime','WebGUI/Prime/AjaxHelper','jquery','can/view/ejs','WebGUI/Prime/SelectList','WebGUI/Prime/Text','jqueryui'],function(Prime, AjaxHelper, $, can, select, text){
   return function(){
      $('button#add-users-button').hide(); // hide the add butto as we don't want to loose our data
      var jsonPath = Prime.config().jsonSourceServer;
      var jsonSubmit = jsonPath + '?op=editUser;uid=new';      
      AjaxHelper({jsonPath:jsonSubmit, callback:function(data){
         // Account section
         $.each(data, function(index, field){
            if ( field.type && field.type === 'select' ){
               field.rendered = select( field );
               
            }
         });
         // Profile section
         $.each(data.profile, function(index, category ){
            $.each( category.values, function(index, field){
               field.rendered = text( field );
               
            });
         
         });
            
         $('#usersContainer').html( can.view(Prime.config().template.path + "people/addUser.ejs", data) );
            
         $('#userAddContainer').tabs();
         $('#userAddContainer').tabs( "option", "active", 0 ); // make sure the first panel is active
                 
         // Save User Clicked
         $('button#saveUser').button().click(function(){
            alert("Save this user, --NOT IMPLEMENTED YET--!");
            $('a#usersTab').click();

         });
      
      }}); 

   };

});
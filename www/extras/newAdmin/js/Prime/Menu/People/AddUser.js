define(['Prime','Prime/AjaxHelper','jquery','can/view/ejs','URIjs/URI','Prime/Menu/People/GroupList','jqueryui'], 
function(Prime, AjaxHelper, $, can, URI, groupList){
   return function(user){
      if ( user ){
         var uri = new URI( user );
         var query = URI.parseQuery( uri.search() );
         user = query.uid;
         
      }else{
         user = 'new';
         
      }

      $('div.user-add-delete-controls').hide(); // hide the add button as we don't want to loose our data
      var jsonPath = Prime.config().jsonSourceServer;
      var jsonSubmit = jsonPath + '?op=editUser&uid=' + user;      
      AjaxHelper({jsonPath:jsonSubmit, callback:function(data){
         // Account section
         $.each(data, function(index, field){
            if ( field.type && field.type === 'select' ){
               field.rendered = can.view.render(Prime.config().template.path + 'selectList.ejs', field);
               
            }
         });
         
         // Add the WebGUI authentication method to the rendered page
         data.authMethod.options.changeUsername.rendered = can.view.render(Prime.config().template.path + 'radio.ejs',{
            class: "auth",
            id:"authWebGUI.changeUsername",
            name: "authWebGUI.changeUsername",
            type: "radio",
            options: data.authMethod.options.changeUsername.options 
         });
         
         data.authMethod.options.changePassword.rendered = can.view.render(Prime.config().template.path + 'radio.ejs',{
            class: "auth",
            id:"authWebGUI.changePassword",
            name: "authWebGUI.changePassword",
            type: "radio",
            options: data.authMethod.options.changePassword.options 
         });         

/*
"authMethod":{
   "options":{
      "password":{
         "extras":"autocomplete=\"off\"",
          "value":"",
           "name":"authWebGUI.identifier",
           "type":"password",
          "label":"Password"
      },
      "interval":{
         "value":"0",
         "name":"authWebGUI.passwordTimeout",
         "label":"Password Timeout",
         "defaultValue":"3122064000"
      }
   },
   "label":"WebGUI"
}
*/  
         
         
         
         // Profile section
         $.each(data.profile, function(index, category ){
            // Notice that we iterate over every field in every section/category
            $.each( category.values, function(index, field){
               var template = null;
               // ::TODO:: rework the toolbar id's/names to make sure there are no collisions with data coming from the internals
               if ( field.id === 'toolbar' ){
                  field.id = 'profileToolbar';
                  field.name = 'profileToolbar';
               }
               
               if ( (/^select/).test( field.type ) ){
                  template = 'selectList.ejs';

               }else if ( field.type === 'radio' ){
                  template = 'radio.ejs';           

               }else if ( field.type === 'image' ){
                  template = 'imageLoader.ejs';

               }else{
                  if ( field.required == 1 ){// don't change from == to ===
                     field.required = 'required';
                  }else{
                     field.required = "";
                  }
                  // for phone numbers match the html5 spec
                  if ( field.type === 'phone' ){
                     field.type = 'tel';
                  }
                  template = 'text.ejs';
               }
               field.rendered = can.view.render(Prime.config().template.path + template, field);
               
            });
         
         });
               
         // Render the contents of the add user container
         $('#usersContainer').html( can.view(Prime.config().template.path + "people/addUser.ejs", data) );
            
         // Make sure tabs are displayed and the first one is selected
         $('#userAddContainer').tabs();
         $('#userAddContainer').tabs( "option", "active", 0 ); // make sure the first panel is active
                 
         // Save User Clicked
         $('button#saveUser').button().click(function(){          
            var jsonSubmit = jsonPath + '?op=editUserSave';
            AjaxHelper({ jsonPath:jsonSubmit, clickAfter:"#usersTab", method:"POST", processData:false, data: $('form#addUserForm').serialize(), logMessage:"Saved" });//::TODO:: i18n
               //infoLogger:groupInfoLogger, errorLogger:groupErrorLogger }); // by default message = saved            
         });
         
         // List the groups assigned to this user  
         var userGroupsTable = groupList('#userDeleteTable',{ op:"listUserGroups&uid=" + user, groupId:"groupsToDelete", data:"groups.options", serverSide:false });
         //availableGroups  
         var userGroupsNotTable = groupList('#userAddTable',{ op:"listUserGroups&not=1&uid=" + user, groupId:"groupsToAdd", data:"availableGroups.options", serverSide:false });      

         $('button#photo_upload').click(function(event){
            event.preventDefault();       
            var action = 'upload';
            require(['Prime/Uploader'],function(uploader){
               event.jsonPath = '/';
               event.op = 'ajaxUploadFile';
               event.file_action = action;
               uploader(event);
            });            
         });

      }}); 

   };

});
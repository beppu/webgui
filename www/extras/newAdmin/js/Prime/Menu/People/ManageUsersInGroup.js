define(['jquery','Prime','Prime/Menu/People/UserList','URIjs/URI','Prime/AjaxHelper','can/view/ejs'],function($,Prime,users,URI,AjaxHelper){
   return function(groupContainer, gid){
      var jsonPath = Prime.config().jsonSourceServer;
      // add a userlist table to the container
      // Making two calls just to get the security token :-(
      AjaxHelper({ jsonPath:jsonPath + '?op=manageUsersInGroup&gid=' + gid, callback:function(data){
         // Once the template and the page is displayed continue displaying the tables.
         $(groupContainer).html( can.view(Prime.config().template.path + 'people/manageUsersInGroup.ejs', data));

         // display the users in the added table
          var usersInGroupTable = users('#userGroupTableList',{ op:"manageUsersInGroup&gid=" + gid });
          // show the userlist in the group Container table, NOTICE the NOT=1 in the query!!!
          var allUsersTable = users('#userGroupList',{ op:"manageUsersInGroup&not=1&gid=" + gid }).on('click', "a", function(event){
             event.preventDefault();
             var jsonPathFromTag = event['target']['href'];
             var uri = new URI( jsonPathFromTag );
             var query = URI.parseQuery( uri.search() );  

          });

          // Add available users to group
          $('input#selectedUsers').button().click(function(){
             var selectedUsers = "";
             // find out which users have been selected
             $('table#userGroupList input.useridCheckbox').each(function(index, element){
                if ( $(element).is(':checked') ){
                   selectedUsers += '&uid=' + $(element).attr('value');
                   $(element).prop('checked',false); // uncheck
                }
             });
             // Only make the webcall if there are any users selected
             if ( selectedUsers.length > 0 ){
                var jsonSubmit = jsonPath + '?op=addUsersToGroupSave&gid=' + gid + selectedUsers;    
                AjaxHelper({ jsonPath:jsonSubmit, callback:function(){
                   usersInGroupTable.fnDraw();
                   allUsersTable.fnDraw();
                }});
             }
          });

          // Delete users from group assigned
          $('input#deleteUsers').button().click(function(){
             var selectedUsers = "";
             // find out which users have been selected
             $('table#userGroupTableList input.useridCheckbox').each(function(index, element){
                if ( $(element).is(':checked') ){
                   selectedUsers += '&uid=' + $(element).attr('value');
                   $(element).prop('checked',false); // uncheck 
                }
             });
             // Only make the webcall if there are any users selected
             if ( selectedUsers.length > 0 ){  
                var jsonSubmit = jsonPath + '?op=deleteGrouping&gid=' + gid + selectedUsers + '&' + $('#groupUserDeleteForm').serialize();
                AjaxHelper({ jsonPath:jsonSubmit, method:"POST", callback:function(){
                   usersInGroupTable.fnDraw();
                   allUsersTable.fnDraw();
                }});
             }
          });      

      }});

   };
   
});
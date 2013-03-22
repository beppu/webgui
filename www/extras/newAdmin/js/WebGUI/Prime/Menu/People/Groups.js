define(['WebGUI/Prime','WebGUI/Prime/Datatable','WebGUI/Prime/CrumbTrailMenu','WebGUI/Prime/MenuItem','WebGUI/Prime/AjaxHelper','WebGUI/Prime/MessageQueue','URIjs/URI'],
function(Prime,dt,CrumbTrailMenu,MenuItem,AjaxHelper,MessageQueue,URI){
   return function(){
      $('#groupContainer').html('<table id="groupDatatable" class="webguiAdminTable"></table>'); // hate to do this but needs to be done for now
      var jsonPath = Prime.config().jsonSourceServer;
      dt('#groupDatatable', { 
         jsonPath:jsonPath + "?op=listGroups",
         datasource:"data",
         columns:[
           {field:'groupId',type:'link',uri:jsonPath + '?op=editGroup&gid=',cssClass:'groupEdit'},
           {field:'groupName',title:'Name'},
           {field:'description',title:'Description'}
         ]
      });
      
      // Menu at top of container, items get added and deleted from this menu dynamically   
      var groupCrumbTrailMenu = new CrumbTrailMenu('#groupCrumbTrailMenu',{ containerId:"#groupContainer", view: Prime.config().template.path + "crumbTrail.ejs" });

      // What happens when we click on a datatable row above.
      $('#groupDatatable').on('click', "tr", function(event){
         var groupInfoLogger = new MessageQueue('div#groupMessageWrapper div.info'); // Create a message queue on the info div
         var groupErrorLogger = new MessageQueue('div#groupMessageWrapper div.error', {type:'error'}); // Create a message queue on the error div
         event.preventDefault();
         var jsonPathFromTag = event['target']['href'];         
         var uri = new URI( jsonPathFromTag );
         var query = URI.parseQuery( uri.search() );
         // Clicked record, go into edit group mode
         if ( query.op && query.gid ){
            var jsonFunction = function(){
                AjaxHelper({jsonPath:jsonPathFromTag, callback:function(data){
                    $('#groupContainer').html( can.view(Prime.config().template.path + "people/group-edit.ejs", data) );
                    // Manage Groups onnce the html is displayed
                    $('input.manage-group').button().click(function( event ) {
                       event.preventDefault();
                       // Get this info from the clicked element
                       var groupActionTarget = new URI( event.target.src );
                       var operation = URI.parseQuery( groupActionTarget.search() );
                       switch(operation.op){
                          case 'editGroupSave':// the operation is already included in the template/form
                             var jsonSubmit = jsonPath + '?' + $('form#groupEditForm').serialize();
                             AjaxHelper({ jsonPath:jsonSubmit, clickAfter:"#groupTab", logMessage:"Saved", infoLogger:groupInfoLogger, errorLogger:groupErrorLogger });                                
                          break;                       

                          case 'deleteGroup':
                             // alert the user to make sure he definitely wants to delete this group
                             $( "#dialog-delete-confirm" ).dialog({
                                 modal: true,
                                 buttons: {
                                    "Delete all items":function(){
                                        var jsonSubmit = jsonPath + '?op=deleteGroup;gid=' + query.gid;
                                        AjaxHelper({ jsonPath:jsonSubmit, clickAfter:"#groupTab", logMessage:"Deleted", infoLogger:groupInfoLogger, errorLogger:groupErrorLogger });
                                        $( this ).dialog( "close" );
                                     },
                                     Cancel: function() {
                                        $( this ).dialog( "close" );
                                     }
                                 }
                             });                                
                          break;

                          case 'manageUsersInGroup':
                             require(['WebGUI/Prime/Menu/People/UserList'],function(users){
                                // add a userlist table to the container
                                $('#groupContainer').html('<table id="userGroupList" class="webguiAdminTable"></table>');
                                // display the users in the added table
                                users('#userGroupList'); // show the userlist in the group Container table
                                //groupCrumbTrailMenu.add(new MenuItem({ href:"#", link:"Users in Group", title:"Manage Users in Group", cssClass:"manage-group" ,callback:jsonFunction }));//i18n ::TODO::
                             });
                          break;                              

                          default:
                             alert ("Still need to implement: " + operation.op);

                       }

                    });
                  } 
               });
            };
            jsonFunction(); // Display the contents            
            
            // Add the menu to click...
            groupCrumbTrailMenu.add(new MenuItem({ href:jsonPathFromTag, link:"Edit Group", title:"Editing group: " + query.gid, callback:jsonFunction }));//i18n ::TODO::
            
         }
      });

      // Add new group
      $('button#addGroup').button().click(function( event ) {
         var groupInfoLogger = new MessageQueue('div#groupMessageWrapper div.info');
         var groupErrorLogger = new MessageQueue('div#groupMessageWrapper div.error', {type:'error'});            
         event.preventDefault();
         var jsonSubmit = jsonPath + '?op=editGroup';         
         var callback = function(data, textStatus, jqXHR){
             $('#groupContainer').html( can.view(Prime.config().template.path + "people/group-edit.ejs", data) );
             // What happens when we click the save button
             $('input.manage-group').button().click(function( event ) {
                var jsonSubmit = jsonPath + '?op=editGroupSave&' + $('form#groupEditForm').serialize();
                AjaxHelper({ jsonPath:jsonSubmit, clickAfter:"#groupTab", data: data, logMessage:"Saved",//::TODO:: i18n
                   infoLogger:groupInfoLogger, errorLogger:groupErrorLogger }); // by default message = saved
             });

         };
         AjaxHelper({ jsonPath:jsonSubmit, infoLogger:groupInfoLogger, errorLogger:groupErrorLogger, callback:callback });

      });
      
   };
   
});
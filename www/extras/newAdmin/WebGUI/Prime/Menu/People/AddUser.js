define(['WebGUI/Prime','WebGUI/Prime/AjaxHelper','jquery','can/view/ejs','jqueryui'],function(Prime, AjaxHelper, $, can){
   return function(){
      var jsonPath = Prime.config().jsonSourceServer;
      var jsonSubmit = jsonPath + '?op=editUser;uid=new';
      
$('#usersContainer').html( can.view(Prime.config().template.path + "people/addUser.ejs", {}) );      
      
/*      AjaxHelper({jsonPath:jsonSubmit, callback:function(data){
         console.log( data );  
         $('#usersContainer').html( can.view(Prime.config().template.path + "people/addUser.ejs", data) );
      
         //$('a#usersTab').click();// Refresh the users table
         
      }}); */
   };

});
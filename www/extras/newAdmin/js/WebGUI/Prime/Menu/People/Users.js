define(['WebGUI/Prime','WebGUI/Prime/Menu/People/UserList'],function(Prime, users){
   return function(){
      $('#usersTarget').html( can.view(Prime.config().template.path + 'people/users.ejs'));
      
      // display the users in the added table
      users('#usersDatatable', {op:"listUsers"} ).on('click', "a", function(event){
         event.preventDefault();
         var jsonPathFromTag = event['target']['href'];
         console.log( jsonPathFromTag ); 

      });
   };
});
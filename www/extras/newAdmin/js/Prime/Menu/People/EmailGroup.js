define(['Prime','Prime/AjaxHelper','can/view/ejs'],function(Prime,AjaxHelper){
  return function(container, gid){
     var jsonPath = Prime.config().jsonSourceServer;
     var jsonSubmit = jsonPath + '?op=emailGroup&gid=' + gid;
     // Get the email group form and display it in the groupContainer area
     AjaxHelper({jsonPath:jsonSubmit, 
        callback:function(data){
           // render the form in the selected container
           $(container).html( can.view(Prime.config().template.path + "people/emailGroup.ejs", data) );
           // Enable the submit button to submit the form via ajax
           $('input#emailGroupSubmit').button().click(function(event) {
              event.preventDefault();
              jsonSubmit = jsonPath + '?op=emailGroupSend&' + $('form#emailGroup').serialize();
              AjaxHelper({jsonPath:jsonSubmit, method:"POST", 
                 callback:function(data){
                    alert( data ); 
                 }
              });             
              
           });

        }
     });    
  };
});

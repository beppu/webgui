define(['jquery','Prime','can/view/ejs','jqueryForm'],function($,Prime,can){
   return function(params){
      var jsonParams = { dataType:'json' };// always receive json data
      if ( ! $.isEmptyObject(params.data) ){
         jsonParams.data = params.data;     
      }
      var jsonPath = params.jsonPath;
      if ( Prime.config().jsonp ){
         jsonPath += '&callback=?';
         jsonParams.crossDomain = true;  
      }
      var file_action = "";
      if ( params.file_action ){
         file_action = params.file_action;
      }
  
      var target = params.currentTarget.id.replace("_upload",""); ;
      var targetForm = '#form_' + target;      
      var operation = params.op;
      $("#dialog-splash").html( 
         can.view(Prime.config().template.path + "uploader.ejs", 
            { form_action: jsonPath, target: target, op: operation, file_action: file_action }) );
      $("#dialog-splash").dialog({
         beforeClose: function( event, ui ){
            var thumbNail = $(targetForm + ' img#image').attr('src');
            var previewTag = '#' + target + '_preview';
            $(previewTag).attr('src', thumbNail);
             
         },
         height: 200,
         width: 300,
         modal: true
      });
            
      $('.fileUpload').change(function(){        
         // use a file progress thingy here!
         $(targetForm).ajaxForm({                 
            success:function(jsonResponse, statusText) {
               $('#fileUploadResponse').html(statusText);
               if ( statusText === "success" ){
                  $(targetForm + ' img#image').attr('src', jsonResponse.thumbnail);
                  $(targetForm + ' td#filename').html( jsonResponse.filename );
                  $('#' + target).attr('value', jsonResponse.id );
                  $("#dialog-splash").dialog( "close" );
               }
            },
            error:function(){
               alert("An AJAX error occured.");
               
            }                               
         }).submit();
         
      }); 
   };   
});
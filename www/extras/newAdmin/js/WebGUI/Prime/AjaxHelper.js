define(['jquery','WebGUI/Prime'],function($,Prime){
   return function(params){  
      var jsonParams = { dataType:'json' };// always receive json data
      if ( ! $.isEmptyObject(params.data) ){
         jsonParams.data = params.data;     
      }
      if ( ! $.isEmptyObject(params.method)){
         jsonParams.type = params.method; // could be lots of data
      }
      var jsonPath = params.jsonPath;
      if ( Prime.config().jsonp ){
         jsonPath += '&callback=?';
         jsonParams.crossDomain = true;  
      }
      // Define the success callback for this call
      jsonParams.success = function(data, textStatus, jqXHR){
         try{
            if ( typeof params.callback !== 'undefined' ){
               params.callback(data);
            }
         }catch(exception){
            console.log("Fix this issue: " + exception);//::TODO:: 
         } 
         if ( ! $.isEmptyObject(data.message) ){
            if ( ! $.isEmptyObject(params.errorLogger) ){ params.errorLogger.add({message:data.message}); };
            if ( ! $.isEmptyObject(params.infoLogger) ){ params.infoLogger.hide(); }
         }else{
            if ( ! $.isEmptyObject(params.infoLogger) && ! $.isEmptyObject(params.logMessage) ){ 
               params.infoLogger.add({message:params.logMessage}); 
            };
            if ( ! $.isEmptyObject(params.errorLogger) ){ params.errorLogger.hide(); }         
         }  
         if ( ! $.isEmptyObject(params.clickAfter) ){         
            $(params.clickAfter).click();
         }         

      };
      
      // Define the error callback for this call
      jsonParams.error = function(jqXHR, textStatus, errorThrown){   
         try{
            params.callback(data);
         }catch(exception){
            console.log("Fix this issue: " + exception);//::TODO:: 
         } 
         var responseMessage = jqXHR.responseText;  
         var message = "";
         try{
            message = responseMessage.message;  
         }catch( exception ){
            message = textStatus + " " + errorThrown;
         }
         if ( ! $.isEmptyObject(params.errorLogger) ){ params.errorLogger.add({message:message}); };
         if ( ! $.isEmptyObject(params.infoLogger) ){ params.infoLogger.hide(); } 
         console.log( message );
      }; 
      
      // Finally, make the call!!!
      $.ajax( jsonPath, jsonParams );
   };   
});

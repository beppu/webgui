// given a page and a div id render the contents
define(['jquery'], function($){
   return function (targetDiv, operation){
      if ( $(targetDiv).exists() ){
         $(targetDiv).load( operation );
      }else{
         throw "You must provide a target to render the content of: " + operation;// ::i18n::
      }
   };
});
/*
 * WebGUI specific module
 */
define(['jquery','Prime','Prime/AjaxHelper','jquerypp'],function($, Prime, AjaxHelper){
   alert("ok");
   return function(){
       alert(  Prime.config().jsonSourceServer + "?op=editSettings" );
       var jsonPath = Prime.config().jsonSourceServer + "?op=editSettings";
        $.getJSON( jsonPath, { }, function(response) {
alert(response);
        } );

   };
});

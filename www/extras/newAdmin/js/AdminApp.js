requirejs.config({
   paths :{
      can       : '/extras/newAdmin/js/libs/can',
      datatables: '/extras/newAdmin/js/libs/jquery.dataTables.min',
      domReady  : '/extras/newAdmin/js/libs/domReady',
      jquery    : '/extras/newAdmin/js/libs/jquery-1.9.1',
      jqueryui  : '/extras/newAdmin/js/libs/jquery-ui-1.10.1.custom.min',
      jquerypp  : '/extras/newAdmin/js/libs/jquerypp.custom',
      URIjs     : '/extras/newAdmin/js/libs/URI'
   },
   config: {
      // Main webgui namespace object for scripts.  This can be put into a template and
      //   retrieved from the WebGUI config system
      "WebGUI/Prime" : {
         error: "",
         errorTag: "#errors",
         errorTemplate: "webgui-ajax-error-template.ejs",
         template: {
            path: "/extras/newAdmin/js/templates/"
         },
         jsonSourceServer: "http://webgui.dbash.com:8900",
         jsonp:false,
         tooltips: true,
         messageTag: "#messages",
         messageTemplate: "webgui-ajax-message-template.ejs"
      }
   }
});

//requirejs.onError = function (err) {
//    console.log(err.requireType);
//    if (err.requireType === 'timeout') {
//        console.log('modules: ' + err.requireModules);
//    }
//alert(err);
//    throw err;
//};

/* 
 * Include this in every page we want to include the adminOn option
 */
require(['domReady','jquery','WebGUI/Prime/AdminMenu','can/view/ejs'],function(domReady, $, adminMenu){
   // Generic helper functions defined in the JQuery namespace
   $.fn.exists = function(){return this.length>0;};
   
   domReady(function(){
      // Make sure we have our turn admin on link!
      if ( $('#turn-admin-on-container').length == 0 ){
         if ( $('#turn-admin-on').length <= 0 ){
            $('body').append('<a id="turn-admin-on" href="javascript://" style="position:absolute;right:10px;top:0">Turn Admin On</a>');
         }
      }else{
         $('#turn-admin-on-container').html('<a id="turn-admin-on" href="javascript://">Turn Admin On</a>');

      }

      $('#turn-admin-on').click(function(){
         if ( $('#adminDiv').size() <= 0 ){ // Only fill out body if the admin menu has not been loaded
            $('#adminDiv').remove();// start with a clean slate
            $('body').append('<div id="adminDiv"></div>'); // this has to be removed once we get out of admin mode
            $('#adminDiv').load('/extras/newAdmin/admin/index.html', adminMenu); // Once the html is loaded attach the adminMenu module
            //var adminTemplate = can.view.render('/admin/index.ejs',{ server: 'http://webgui.dbash.com:8900' });
            //$('#adminDiv').html( adminTemplate ).ready( adminMenu );
            $('#toolbar').show();

            // Ajax Global ERROR setup
            $(document).ajaxError(function(event, jqxhr, settings, exception){
               function final_message(url, message){
                  alert("Error requesting page: " + ajax_url + " because: " + message); // ::TODO:: i18n
                  $( "#ajaxErrors" ).append( "Error requesting page: " + ajax_url + " because: " + message); // ::TODO:: i18n
               }            
      //         var browser    = BrowserDetect.browser;
      //         var browserVer = BrowserDetect.version;
      //         var browserOS  = BrowserDetect.OS;
               var ajax_url   = settings.url;
               var ERROR_MSG = "Error happened: ";// ::TODO:: i18n

               // Finally, make the call!!!
               if (jqxhr.status === 0) {
                  final_message(ERROR_MSG + '0'); // Not connected. Please verify network is connected.
               } else if (jqxhr.status == 404) {
                  final_message(ERROR_MSG + '404'); // Requested page not found. [404]
               } else if (jqxhr.status == 500) {
                  final_message(ERROR_MSG + '500'); // Internal Server Error [500].
               } else if (exception === 'parsererror') {
                  final_message(ERROR_MSG + '1'); // Requested JSON parse failed.
               } else if (exception === 'timeout') {
                  final_message(ERROR_MSG + '2'); // Time out error.
               } else if (exception === 'abort') {
                  final_message(ERROR_MSG + '3'); // Ajax request aborted.
               } /*else {
                  if(browserVer == '7' && browser == 'Explorer') {
                     final_message(ERROR_MSG + '100'); // Uncaught Error
                  } else {
                     final_message(ERROR_MSG + '99'); // Uncaught Error
                  }
               }*/

            }); 
         }
      });
   });
});

EnableTooltips = function(selector){//::TODO:: figure out how to enable this based on a flag in the config
   if ( $.isEmptyObject(selector) ){ 
      $(".tooltip").tooltip();
   }else{
      $(selector).tooltip();        
   }    
};

function getLink(config){
   return function( data, type, full ) {
      return can.view.render('/extras/newAdmin/js/templates/link.ejs',{
         class:config.cssClass,
         image:config.image,
         title:config.title || data,
           uri:config.uri + data
      });
   };          
}

function getCheckbox(config){
   return function ( id, type, full ) {
      return can.view.render('/extras/newAdmin/js/templates/checkbox.ejs', { 
         class:config.cssClass, 
          name:config.name, 
         value:id
      });
   };      
}

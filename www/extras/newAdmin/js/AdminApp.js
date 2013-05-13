requirejs.config({
   paths :{
      can       : '/extras/newAdmin/js/libs/can',
      datatables: ['//ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min',
                   '/extras/newAdmin/js/libs/jquery.dataTables.min'],
      domReady  : '/extras/newAdmin/js/libs/domReady',
      jquery    : [
                   '/extras/newAdmin/js/libs/jquery-1.9.1',
                   '//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min'
                  ],
      jqueryui  : [
                   '/extras/newAdmin/js/libs/jquery-ui-1.10.1.custom.min',
                   '//ajax.googleapis.com/ajax/libs/jqueryui/1.10.2/jquery-ui.min'
                  ],
      jquerypp  : '/extras/newAdmin/js/libs/jquerypp.custom',
      jqueryForm: '/extras/newAdmin/js/libs/jquery.form',
      URIjs     : '/extras/newAdmin/js/libs/URI',
      modernizr : "/extras/newAdmin/js/libs/modernizr-2.6.2.min"
   },
   config: {
      // Main webgui namespace object for scripts.  This can be put into a template and
      //   retrieved from the WebGUI config system
      "Prime" : {
         basePath:"/extras/newAdmin/",
         error: "",
         errorTag: "#errors",
         errorTemplate: "webgui-ajax-error-template.ejs",
         template: {
            path: "/extras/newAdmin/js/templates/"
         },
         jsonSourceServer: "/",
         jsonp:false,
         otherHelp:'/extras/newAdmin/help.json',
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
require(['domReady','jquery','Prime','Prime/AdminMenu','can/view/ejs','jqueryui','modernizr'],function(domReady, $, Prime, adminMenu, can, jqueryui, modernizr){
   // Generic helper functions defined in the JQuery namespace
   // check to make sure html element exists
   $.fn.exists = function(){return this.length>0;};
   
   // HTML5 Boilerplate code!!!
   // Avoid `console` errors in browsers that lack a console.
   if (!(window.console && console.log)) {
       (function() {
           var noop = function() {};
           var methods = ['assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error', 'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log', 'markTimeline', 'profile', 'profileEnd', 'markTimeline', 'table', 'time', 'timeEnd', 'timeStamp', 'trace', 'warn'];
           var length = methods.length;
           var console = window.console = {};
           while (length--) {
               console[methods[length]] = noop;
           }
       }());
   }   
   
   // Google Analytics: change UA-XXXXX-X to be your site's ID.
   // Enable when you are ready.
   /* var _gaq=[['_setAccount','UA-XXXXX-X'],['_trackPageview']];
   (function(d,t){var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
   g.src=('https:'==location.protocol?'//ssl':'//www')+'.google-analytics.com/ga.js';
   s.parentNode.insertBefore(g,s)}(document,'script'));   */
   
   domReady(function(){
      // Make sure we have our turn admin on link!
      if ( $('#turn-admin-on-container').exists() ){
         $('#turn-admin-on-container').html('<a id="turn-admin-on" href="javascript://">Turn Admin On</a>');
     
      }else{
         if ( ! $('#turn-admin-on').exists() ){
            $('body').append('<a id="turn-admin-on" href="javascript://" style="position:absolute;right:10px;top:0">Turn Admin On</a>');
         }
      }
      
      // Load the stylesheets
      loadCss("/extras/newAdmin/css/normalize.css");
      loadCss("/extras/newAdmin/css/main.css"); // The admin toolbar css is in here!!!
      loadCss("/extras/newAdmin/css/admin-datatable.css");
      loadCss("/extras/newAdmin/css/ui-lightness/main.css");

      // Add click event to enable menu when element clicked
      $('#turn-admin-on').click(function(){
         if ( $('#adminDiv').size() <= 0 ){ // Only fill out body if the admin menu has not been loaded
            $('#adminDiv').remove();// start with a clean slate
            $('body').append('<div id="adminDiv"></div>'); // this has to be removed once we get out of admin mode
            $('#adminDiv').load(Prime.config().basePath + 'admin/index.html', adminMenu); // Once the html is loaded attach the adminMenu module
            //var adminTemplate = can.view.render('/admin/index.ejs',{ server: 'http://webgui.dbash.com:8900' });
            //$('#adminDiv').html( adminTemplate ).ready( adminMenu );
            $('#toolbar').show();
            
            // Enable tooltips for the admin menu
            $(".tooltip").tooltip();
            
            // Ajax Global ERROR setup
            $(document).ajaxError(function(event, jqxhr, settings, exception){
               function final_message(url, message){
                  alert("Error requesting page: " + ajax_url + " because: " + message); // ::TODO:: i18n
                  // show this error on the ajaxErrors element that has a ajaxErrors id.
                  if ( $("#ajaxErrors").exists() ){
                     $( "#ajaxErrors" ).append( "Error requesting page: " + ajax_url + " because: " + message); // ::TODO:: i18n
                  }
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

// Helper function to load css
function loadCss(url) {
    var link = document.createElement("link");
    link.type = "text/css";
    link.rel = "stylesheet";
    link.href = url;
    document.getElementsByTagName("head")[0].appendChild(link);
}

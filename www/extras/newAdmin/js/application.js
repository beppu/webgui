/*
 *Helper methods.
*/
//if ($(selector).exists()) {
//    // Do something
//}
$.fn.exists = function(){return this.length>0;};

// Main webgui namespace object for scripts.  This can be put into a template and
//   retrieved from the WebGUI config system
   WebGUI = {
      Prime : {
         error: "",
         errorTag: "#errors",
         errorTemplate: "webgui-ajax-error-template.ejs",
         template: {
            "path":"/extras/newAdmin/js/templates/"
         },
         tooltips: true,
         messageTag: "#messages",
         messageTemplate: "webgui-ajax-message-template.ejs"
      }
   };

/*
 * Must create these types of menu items to be added to the dynamic menus.
 */
var MenuDynamic = can.Construct({},{
   init:function(href,link,title){
      this.id    = Math.random();
      this.href  = href;
      this.link  = link; 
      this.title = title;
   },
   equals:function(menuItem){
      if ( menuItem instanceof MenuDynamic ){
         if ( this.id === menuItem.id ){
            return true;
         }else{
            return false;
         }
      }else{
         return false;
      }
   },
   id:function(){ return this.id; },
   href:function(){ return this.href; },
   link:function(){ return this.link; },
   title:function(){ return this.title; }
});

/* Menu has a few options.
 * id = The UL tag id
 * view = the ejs template used to generate the menu, see default template crumbTrail.ejs
 * source = the json datasource
 *    should be in the form [{ "id": "1", "title": "...", "href": "/?op=1", "link": "Home"  },...]
 *    will create an anchor tag: 
 *    <ul [id=...] class="webgui_breadcrumb_container">
 *       <li class="webgui_breadcrumb_item"><a href="/?op=1" title="">Home</a></li>
 *       ...
 *    </ul>
*/
var MenuFromJson = can.Control({
   defaults: {
      levels: 5,
      view: WebGUI.Prime.template.path + 'crumbTrail.ejs' 
   }
},{
   'init': function( element , options ) {
      // Build the model that actually retrieves the menus, the items should be filtered and 
      //   sorted on the server
      var MenuItems = can.Model({ findAll : 'GET ' + options.source + '?levels=' + options.levels }, {});
      // Retrieve the menu items, render them in the container using the assigned template 
      MenuItems.findAll({}, function( items ) {
         $( element ).html( can.view( options.view, { items:items, id:options.id } ) );
      });
   },
   "li click" : function(li, event){
      event.preventDefault(); // suppress the click event
      event.stopPropagation();
      var link  = li.data('link');
      var divId = this.options.divId; 
      renderPage( divId, link.href );
   }
});

/*
 *  Creates a dynamic crumbtrail menu in the passed div
 */
var CrumbTrailMenu = can.Control({
   defaults: {
      levels: 5,
      view: WebGUI.Prime.template.path + 'crumbTrail.ejs' 
   }      

},{
   'init': function( element , options ) {
      if ( options.items != null ){ // do NOT change!!!
         this.menuItems = options.items;
      }else{
         this.menuItems = new can.Observe.List([]);          
      }


      if ( options.id !== null ){
         this.id = options.id;
      }
      element.html( can.view( options.view, { id:this.id, items:this.menuItems } ) );
   },
   'li click':function(li, event){
      event.preventDefault();
      var link  = li.data('link');
      // remove everything after the clicked item
      var instancePosition = 0;
      for( var index = 0; index < this.menuItems.length; index++ ){// menu should not be empty
         if ( link.equals( this.menuItems[index] ) ){
            instancePosition = index + 1;
            break;//we are out of here!
         }
      }
      while( instancePosition > 0 && this.menuItems.length > instancePosition ){
         this.menuItems.pop();
      }

      var divId = this.options.divId; // Where we display the contents of the requested path
      loadPage( divId, link.href );

   },
   add:function(menuItem){
      if ( menuItem instanceof MenuDynamic ){
         this.menuItems.push(menuItem);
      }else{
         throw "You must pass an instance of: MenuDynamic";//::i18n::
      }
   },
   count:function(){
      return this.menuItems.length;
   }
});

// given a page and a div id render the contents
function loadPage(targetDiv, operation){
   if ( $(targetDiv).exists() ){
      $(targetDiv).load( operation );
   }else{
      throw "You must provide a target to render the content of: " + operation;// ::i18n::
   }
}

// Generic logger function for failed ajax calls
function logAjaxError(error){
   if ( error ){
      $(document).ajaxError(function(event, request, settings){
         $( WebGUI.Prime.errorTag ).append( 
            can.view( WebGUI.Prime.template.path + WebGUI.Prime.errorTemplate, { message: error, settings: settings } ) 
         ).show();
      });
   }
}

/*
 * Display and destroy messages
 */
var MessageQueue = can.Control({
      defaults:{
         type:"info",
         view:WebGUI.Prime.template.path + "messageQueue.ejs"
      }
   },{
   init:function(element, options){
      element.hide();
      this.messages = new can.Observe.List([]);
      $( element ).html( can.view(options.view, { type:options.type, messages:this.messages }) );
   },
   add:function(message){
      this.element.show();
      this.messages.push(message);
   },
   hide:function(){
      this.element.hide(); 
   },
   remove:function(){
      if ( typeof this.element !== 'undefined' && this.element != null ){
         this.element.remove();
      }
   }
});

/*
 * Generic JSON helper function
 */
WebGUI.Prime.AjaxHelper = function(params){
   if ( params.method == 'undefined' || params.method == null ){
      params.method = 'GET';
   }
   if ( params.logMessage == 'undefined' || params.logMessage == null ){
      params.logMessage = 'Saved';//i18n ::TODO::
   }
   $.ajax({ url:params.jsonPath, type:params.method }) // could be lots of data
    .done(function(data, textStatus, jqXHR){
       if ( typeof data.message !== 'undefined' && data.message.length > 0 ){
          if ( params.errorLogger != null ){ params.errorLogger.add({message:data.message}); };
          if ( params.infoLogger != null ){ params.infoLogger.hide(); }
       }else{
          if ( params.infoLogger != null ){ params.infoLogger.add({message:params.logMessage}); };
          if ( params.errorLogger != null ){ params.errorLogger.hide(); }         
       }
       if ( params.clickAfter != 'undefined' && params.clickAfter != null ){
          $(params.clickAfter).click();
       }         
       
   })
   .fail(function(jqXHR, textStatus, errorThrown){
      var message = textStatus + " " + errorThrown;        
      if ( params.errorLogger != null ){ params.errorLogger.add({message:message}); };
      if ( params.infoLogger != null ){ params.infoLogger.hide(); }      
      logAjaxError( message );
   });
};
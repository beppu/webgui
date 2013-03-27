/*
 *  Creates a dynamic crumbtrail menu in the passed div
 */
define(['WebGUI/Prime','WebGUI/Prime/LoadPage','WebGUI/Prime/MenuItem','can/control'], 
   function(Prime,loadPage,MenuItem){
   return can.Control({
      defaults: {
         levels: 5,
         view: Prime.config().template.path + 'crumbTrail.ejs' 
      }      

   },
   {
      'init': function( element, options ) {
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

         if ( typeof link.callback !== 'undefined' ){
            // Execute the callback function instead of loading the content from web path
            link.callback();
            
         }else{
            var containerId = this.options.containerId; // Where we display the contents of the requested path
            loadPage( containerId, link.href );
         }

      },
      add:function(menuItem){
         if ( menuItem instanceof MenuItem ){
            this.menuItems.push(menuItem);
         }else{
            throw "You must pass an instance of: MenuItem";//::i18n::
         }
      },
      // Good option if we want to make sure we 
      callback:function(callback){
          this.options.callback = callback;
      },
      count:function(){
         return this.menuItems.length;
      }
   });
});
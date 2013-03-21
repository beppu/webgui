/*
 * Must create these types of menu items to be added to the dynamic menus.
 */
define(['can/construct'],function(Construct){
   var MenuItem = Construct({},{
      init:function(config){
         this.id    = Math.random();
         this.href  = config.href;
         this.link  = config.link; 
         this.title = config.title;
         this.cssClass = config.cssClass;
         this.callback = config.callback;
      },
      equals:function(menuItem){
         if ( menuItem instanceof MenuItem ){
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
      title:function(){ return this.title; },
      cssClass:function(){ return this.cssClass; },
      callback:function(){ return this.callback; }
   });
   
   return MenuItem;   
});

/*
 * Must create these types of menu items to be added to the dynamic menus.
 */
define(['can/construct'],function(Construct){
   MenuItem = Construct({},{
      init:function(href,link,title){
         this.id    = Math.random();
         this.href  = href;
         this.link  = link; 
         this.title = title;
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
      title:function(){ return this.title; }
   });
   
   return MenuItem;   
});

define(['Prime','can/view/ejs'],function(Prime, can){
   return function(config){
      return function ( id, type, full ) {
         return can.view.render(Prime.config().template.path + 'checkbox.ejs', { 
            class:config.cssClass, 
             name:config.name, 
            value:id
         });
      };      
   };
});
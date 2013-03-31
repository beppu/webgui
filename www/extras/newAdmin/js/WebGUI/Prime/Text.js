define(['WebGUI/Prime','can/view/ejs'],function(Prime, can){
   return function(config){
      return can.view.render(Prime.config().template.path + 'text.ejs',{
            id:config.id,
         class:config.class,
          name:config.name,
         value:config.value
      });
   };
});
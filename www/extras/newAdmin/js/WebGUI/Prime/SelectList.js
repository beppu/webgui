define(['WebGUI/Prime','can/view/ejs'],function(Prime, can){
   return function(config){
      return can.view.render(Prime.config().template.path + 'selectList.ejs',{
            id:config.id,
         class:config.class,
          name:config.name,
       options:config.options || []
      });
   };
});
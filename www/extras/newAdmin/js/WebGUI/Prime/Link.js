define(['WebGUI/Prime','can/view/ejs'],function(Prime, can){
   return function(config){
      return function( data, type, full ){// This is a datatable specific thing
         return can.view.render(Prime.config().template.path + 'link.ejs',{
            class:config.cssClass,
            image:config.image,
            title:config.title || data,
              uri:config.uri + data
         });
      };
   };
});
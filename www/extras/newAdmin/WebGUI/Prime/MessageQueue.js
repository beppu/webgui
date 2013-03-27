define(['WebGUI/Prime','jquery','can/view/ejs','can/control','can/observe'],function(Prime,$,can){
   return can.Control(
      {
         defaults:{
            type:"info",
            view:Prime.config().template.path + "messageQueue.ejs"
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
            if ( typeof this.element !== 'undefined' && this.element !== null ){
               this.element.remove();
            }
         }     
      }
   );
   
});
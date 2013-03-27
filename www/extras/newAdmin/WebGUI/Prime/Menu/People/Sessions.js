/*
 * WebGUI specific module
 */
define(['jquery','WebGUI/Prime','WebGUI/Prime/AjaxHelper','WebGUI/Prime/Datatable','jquerypp'],function($, Prime, AjaxHelper, dt){
   return function(){
      var sessionsDatatable = dt('#sessionsDatatable', { 
         jsonPath:Prime.config().jsonSourceServer + "?op=viewActiveSessions",
         datasource:"data",
         columns:[
            { field:"sessionId", title:"Session Id"},
            { field:"userId", title:"User Id" }, 
            { field:"lastIP", title:"Last IP" }, 
            { field:"lastPageView", title:"Last Page View" }, 
            { field:"username", title:"Username" },
            { field:"expires", title:"Expires", sortable:true },
            { field:"sessionId", title:"Kill", name:"sid", type:"checkbox", cssClass:'killSession' }
         ]
      });

      //  toggle all session checkboxes
      $('#kill-all-toggle').click(function(){
         var master = $(this).is(':checked');
         $('.killSession').each(function(){ 
            if ( $.cookie("wgSession") !== $(this).attr('value') ){
               $(this).prop('checked',master);
            }
         });
      });

      // When we want to kill a session 
      $('#kill-sessions-button').button().click(function( event ) {
         var sid = "";
         $(".killSession").each(function(){
            // Do not kill my session
            if ( $.cookie("wgSession") !== $(this).attr('value') && $(this).is(':checked') ){
               sid += $(this).attr('value') + ',';
            }
         });

         if ( sid.length > 10 ){
            $( "#dialog-delete-confirm" ).dialog({
               modal: true,
               buttons: {
                  "Delete all items":function(){
                     var jsonPath = Prime.config().jsonSourceServer + '?op=killSession&sid=' + sid;
                     AjaxHelper({ jsonPath: jsonPath });
                     sessionsDatatable.fnDraw();// refresh the table once I remove the session
                     $( this ).dialog( "close" );
                  },
                  Cancel: function() {
                     $( this ).dialog( "close" );
                  }
               }
            });
         }
      });   
   };
});
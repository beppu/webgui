define(['WebGUI/Prime','WebGUI/Prime/Datatable'],function(Prime,dt){
   return function(){
      var loginHistoryDatatable = dt('#loginHistoryDatatable', { 
         jsonPath:Prime.config().jsonSourceServer + "?op=viewLoginHistory",
         datasource:"data",
         columns:[
            { field:"username", title:"User Id"},
            { field:"status", title:"Status"},
            { field:"timeStamp", title:"Login Time"},
            { field:"ipAddress", title:"IP Address"},            
            { field:"userAgent", title:"User Agent"},
            { field:"sessionId", title:"Session Signature"},            
            { field:"lastPageViewed", title:"Last Page View"},
            { field:"sessionLength", title:"Session Length"}
         ]
      });
   };
});
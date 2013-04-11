define(['Prime','Prime/Datatable'], function(Prime,dt){
   return function(tagReference, config){
      if ( typeof config === 'undefined' ){
         config = {};
      }
      var appendToQuery = "";
      if ( typeof config.limit !== 'undefined' && config.limit > 0 ){
         appendToQuery += '&limit=' + config.limit;
      }
      if ( typeof config.op === 'undefined' ){
         config.op = "listUsers"; // sensible default
      }

      var jsonPath = Prime.config().jsonSourceServer;
      
      return dt(tagReference, { 
         jsonPath:jsonPath + "?op=" + config.op + appendToQuery,
         datasource:"users",
         columns:[
           {field:'id',uri:'?op=editUser&uid=',type:'link',cssClass:'useridLink'}, 
           {field:'username',title:'Username'},
           {field:'created',title:'Created'},
           {field:'email',title:'Email'},
           {field:'status',title:'Status'},   //use filter here        
           {field:'updated',title:'Updated'},
           {field:'id',type:'checkbox',name:'userid',cssClass:'useridCheckbox'}
         ]
      });
//     "metrics":{"lastView":null,"status":null,"totalTime":null,"lastLogin":null}      
   };
});
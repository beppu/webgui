define(['WebGUI/Prime','WebGUI/Prime/Datatable'], function(Prime,dt){
   return function(tagReference, config){
      var appendToQuery = "";
      if ( typeof config !== 'undefined' && typeof config.limit !== 'undefined' && config.limit > 0 ){
         appendToQuery += '&limit=' + config.limit;
      }

      var jsonPath = Prime.config().jsonSourceServer;
      dt(tagReference, { 
         jsonPath:jsonPath + "?op=listUsers" + appendToQuery,
         datasource:"users",
         columns:[
           {field:'id',title:'User Id'}, 
           {field:'username',title:'Username'},
           {field:'created',title:'Created'},
           {field:'email',title:'Email'},
           {field:'status',title:'Status'},           
           {field:'updated',title:'Updated'}
         ]
      });
//     "metrics":{"lastView":null,"status":null,"totalTime":null,"lastLogin":null}      
   };
});
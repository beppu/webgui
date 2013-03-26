define(['WebGUI/Prime','WebGUI/Prime/Datatable'], function(Prime,dt){
   return function(tagReference, config){
      var appendToQuery = "";
      if ( typeof config !== 'undefined' && typeof config.limit !== 'undefined' && config.limit > 0 ){
         appendToQuery += '&limit=' + config.limit;
      }
      if ( typeof config.op === 'undefined' ){
         throw "op not specified in config object";//::TODO:: i18n
      }

      var jsonPath = Prime.config().jsonSourceServer;
      
      return dt(tagReference, { 
         jsonPath:jsonPath + "?op=" + config.op + appendToQuery,
         datasource:"users",
         columns:[
           {field:'id',uri:jsonPath + '?op=editUser&uid=',type:'link',cssClass:'useridLink'}, 
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
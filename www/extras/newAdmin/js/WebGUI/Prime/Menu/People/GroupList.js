define(['WebGUI/Prime','WebGUI/Prime/Datatable'], function(Prime,dt){
   return function(tagReference, config){
      var appendToQuery = "";
      if ( typeof config !== 'undefined' && typeof config.limit !== 'undefined' && config.limit > 0 ){
         appendToQuery += '&limit=' + config.limit;
      }
      if ( typeof config.op === 'undefined' ){
         throw "op not specified in config object";//::TODO:: i18n
      }
      if ( ! config.data ){
         config.data = 'data';
      }
      if ( ! config.groupId ){
         config.groupId = "groupId";
      }

      var jsonPath = Prime.config().jsonSourceServer;
      
      return dt(tagReference, { 
         jsonPath:jsonPath + "?op=" + config.op + appendToQuery,
         datasource:config.data,
         columns:[
           {field:'groupId',title:"Group id"},
           {field:'groupName',title:"Group Name"},
           {field:'description',title:"Description"},           
           {field:'groupId',type:'checkbox',name:config.groupId,cssClass:'groupIdCheckbox'}         
         ]
      });   
   };
});
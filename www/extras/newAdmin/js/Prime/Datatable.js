define(['jquery','Prime/AjaxHelper','Prime/Link','Prime/CheckBox','datatables'],function($,AjaxHelper,link,checkbox){   
   return function(target, config){
      var jsonPath = config.jsonPath;
      // Define wether we should do search, pagination or refreshing data by making a trip back to the server
      var serverSide = true;
      if ( config.serverSide && config.serverSide === false ){
         serverSide = false;
      }
      // Configure the columns
      var columns = [];
      config.columns.forEach(function(column){
         var configColumn = {
            mData:column.field,
            sTitle:column.title
         };
         if ( typeof column.sortable !== 'undefined' && column.sortable !== null ){
            configColumn.bSortable = true;
         }else{
            configColumn.bSortable = false;
         }
         // 
         switch( column.type ){
            case 'link':
               configColumn.mRender = link(column);
               break;
            case 'checkbox':
               configColumn.mRender = checkbox(column);
               break;               
         }

         columns.push(configColumn);
      });
      
      return $(target).dataTable({
         "bJQueryUI"    : true, // enable jquery themeroller
         "bAutoWidth"   : false,
         "bProcessing"  : true,
         "bRetrieve"    : true,
         "aoColumns"    : columns,
         "bServerSide"  : serverSide,
         "sAjaxDataProp": config.datasource,
         "sAjaxSource"  : jsonPath,
         "fnServerData": function( jsonPath, aoData, fnCallback ){
            AjaxHelper({ jsonPath: jsonPath, data:aoData, callback:fnCallback });
         }
      });
   };
});
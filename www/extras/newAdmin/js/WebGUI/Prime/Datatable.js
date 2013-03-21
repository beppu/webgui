define(['jquery','WebGUI/Prime/AjaxHelper','datatables'],function($,AjaxHelper){   
   return function(target, config){
      var jsonPath = config.jsonPath;
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
               configColumn.mRender = getLink(column);
               break;
            case 'checkbox':
               configColumn.mRender = getCheckbox(column);
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
         "bServerSide"  : true,
         "sAjaxDataProp": config.datasource,
         "sAjaxSource"  : jsonPath,
         "fnServerData": function( jsonPath, aoData, fnCallback ){
            AjaxHelper({ jsonPath: jsonPath, data:aoData, callback:fnCallback });
         }
      });
   };
});
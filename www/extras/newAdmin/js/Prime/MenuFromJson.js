/* Menu has a few options.
 * id = The UL tag id
 * view = the ejs template used to generate the menu, see default template crumbTrail.ejs
 * source = the json datasource
 *    should be in the form [{ "id": "1", "title": "...", "href": "/?op=1", "link": "Home"  },...]
 *    will create an anchor tag: 
 *    <ul [id=...] class="webgui_breadcrumb_container">
 *       <li class="webgui_breadcrumb_item"><a href="/?op=1" title="">Home</a></li>
 *       ...
 *    </ul>
*/
define(['jquery','Prime','Prime/LoadPage','can/view/ejs','can/control','can/model'],function($,Prime,loadPage,can){
   return can.Control({
         defaults: {
            levels: 5,
            view: Prime.config().template.path + 'crumbTrail.ejs' 
         }
      },{
      'init': function( element , options ) {
         // Build the model that actually retrieves the menus, the items should be filtered and 
         //   sorted on the server
         var MenuItems = can.Model({ findAll : 'GET ' + options.source + '?levels=' + options.levels }, {});
         // Retrieve the menu items, render them in the container using the assigned template 
         MenuItems.findAll({}, function( items ) {
            $( element ).html( can.view( options.view, { items:items, id:options.id } ) );
         });
      },
      "li click" : function(li, event){
         event.preventDefault(); // suppress the click event
         event.stopPropagation();
         var link  = li.data('link');
         var divId = this.options.divId; 
         loadPage( divId, link.href );
      }
   });
});

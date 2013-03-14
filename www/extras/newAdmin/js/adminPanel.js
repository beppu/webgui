WebGUI.Prime.AcitaveAdminPanel = function (){
   /* --------------------- Admin Panel stuff ----------------
   * What happens when we click on an admin function
   *    link must have the showPanel class, make sure it also has a title
   * show error on invalid configuration of menu    */
   $('.showAdminPanel').on('click', function(event){ 
      event.preventDefault();
      // set the title of the overlay panel to be title of link
      $('#adminOverlayTitle').html( $(this).attr('title') );      
      $('#adminOverlayContent').remove();// start with a clean slate
      $('#adminOverlay').append('<div id="adminOverlayContent"></div>');
      if ( $(this).attr('href') === "" ){
         // Clear the title
         $('#adminOverlayTitle').contents().remove();
         $('#adminOverlayCloseWrapper').hide();
         // Clear the contents
         $('#adminOverlayContent').html(
           '<div id="dialog-message" title="Error">' +
              '<p>' +
                '<span class="ui-icon ui-icon-alert" style="float: left; margin: 0 7px 50px 0;"></span>' +
                'You did not specify an href attribute!' + // ::TODO:: i18n
              '</p>' +
           '</div>'
         );
         $( "#adminOverlayContent #dialog-message" ).dialog({
            modal: true,
            buttons: {
               Ok: function() {
                  $( this ).dialog( "close" );
                  $('#adminOverlayCloseWrapper').click();
               }
            }
         }); 
         
      }else{ 
         $('#adminGhost').show();
         // Set the margins for the admin overlay panel       
         var toolbarHeight = $('#toolbar').height();
         var topPadding = (toolbarHeight + 20);
         var bottomPadding = 20;
         var overlayWidth = Math.round( $(document).width() * .9 ); // 90%
         var adminOverlayPaddingLeft = Math.round( ( $(document).width() - overlayWidth ) / 2 ); 
         $('#adminOverlay').css({
            'top': topPadding,
            'left': adminOverlayPaddingLeft,
            'bottom': bottomPadding
         });
         // Set the contents of the admin overlay using the target of the clicked link as a source
         $('#adminOverlayContent').load( $(this).attr('href'), function(event){
            $('#adminOverlay').show();
            $('#adminOverlayCloseWrapper').show();                             
                                        
         });

      }
      
   });
   // Close the admin panel/overlay
   $('#adminOverlayCloseWrapper').click(function(){
      $('#adminOverlay').hide();
      $('#adminGhost').hide(); 
   });
   // Switch on the admin menu
   $('#turn-admin-on').click(function(){
      $('#toolbar').show();
   });   
   // Switch off the admin menu
   $('#turn-admin-off').click(function(){
      $('#toolbar').hide();
      $('#adminOverlayCloseWrapper').click(); // close the admin panel if it is running   
   });
   // Show and hide shortcut menu
   $('.toggle, .toggle-active').click(function(){
      if ( $('#toolbar-drawer').is(":hidden") ) {
         $('#toolbar-drawer').show("slow");
      }else {
         $('#toolbar-drawer').slideUp();
      }
   });

   $('#adminOverlayCloseWrapper').click(); // close the admin panel if it is running
};
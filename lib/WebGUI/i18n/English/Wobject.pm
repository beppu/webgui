package WebGUI::i18n::English::Wobject;

our $I18N = {

          '828' => {
                     lastUpdated => 1053469640,
                     message => q|Most wobjects have templates that allow you to change the layout of the wobject's user interface. Those wobjects that do have templates all have a common set of template variables that you can use for layout, as well as their own custom variables. The following is a list of the common template variables shared among all wobjects.
<p/>
<b>title</b><br/>
The title for this wobject.
<p/>

<b>displayTitle</b><br/>
A conditional variable for whether or not the title should be displayed.
<p/>

<b>description</b><br/>
The description of this wobject.
<p/>

<b>wobjectId</b><br/>
The unique identifier that WebGUI uses to control this wobject.
<p/>

<b>isShortcut</b><br />
A conditional indicating if this wobject is a shortcut to an original wobject.
<p />

<b>originalURL</b><br />
If this wobject is a shortcut, then this URL will direct you to the original wobject.
<p />|
                   },
          '1079' => {
                      lastUpdated => 1073152790,
                      message => q|Printable Style|
                    },
          '827' => {
                     lastUpdated => 1052046436,
                     message => q|Wobject Template|
                   },
          '632' => {
                     lastUpdated => 1110135335,
                     message => q|<p>You can add wobjects by selecting from the <I>^International("1","WebGUI");</I> pulldown menu. You can edit them by clicking on the "Edit" button that appears directly above an instance of a particular wobject while in Admin mode.</p>
<p>Wobjects are Assets, so they have all of the properties that Assets do.  Additionally, most Wobjects share some basic properties. Those properties are:</p>

<P><B>^International("174","Wobject");</B><BR>
Do you wish to display the Wobject's title? On some sites, displaying the title is not necessary. 

<P><b>^International("1073","Wobject");</b><br>
Select a style template from the list to enclose your Wobject if it is viewed directly.  If the Wobject
is displayed as part of a Layout Asset, the Layout Asset's <b>Style Template</b> is used instead.

<p><b>^International("1079","Wobject");</b><br>
This sets the printable style for this page to be something other than the WebGUI Default Printable Style.  It behaves similarly to the <b>Style Template</b> with respect to when it is used.

<P><B>^International("85","Wobject");</B><BR>A content area in which you can place as much content as you wish. For instance, even before a FAQ there is usually a paragraph describing what is contained in the FAQ. 

<P><B>^International("895","Wobject");</B><BR>The amount of time this page should remain cached for registered users.  

<P><B>^International("896","Wobject");</B><BR>The amount of time this page should remain cached for visitors.
|
                   },
          '626' => {
                     lastUpdated => 1101775387,
                     message => q|Wobjects are the true power of WebGUI. Wobjects are tiny pluggable applications built to run under WebGUI. Articles, message boards and polls are examples of wobjects.
Wobjects can be standalone pages all by themselves, or can be individual parts of pages.
<p>

To add a wobject to a page, first go to that page, then select <b>Add Content...</b> from the upper left corner of your screen. Each wobject has it's own help so be sure to read the help if you're not sure how to use it.
<p>
|
                   },
          '42' => {
                    lastUpdated => 1031514049,
                    message => q|Please Confirm|
                  },
          '677' => {
                     lastUpdated => 1047858650,
                     message => q|Wobject, Add/Edit|
                   },
          '174' => {
                     lastUpdated => 1031514049,
                     message => q|Display the title?|
                   },
          '1073' => {
                      lastUpdated => 1070027660,
                      message => q|Style Template|
                    },
          '44' => {
                    lastUpdated => 1031514049,
                    message => q|Yes, I'm sure.|
                  },
          '85' => {
                    lastUpdated => 1031514049,
                    message => q|Description|
                  },
          '895' => {
                     lastUpdated => 1056292971,
                     message => q|Cache Timeout|
                   },
          '896' => {
                     lastUpdated => 1056292980,
                     message => q|Cache Timeout (Visitors)|
                   },
          '664' => {
                     lastUpdated => 1031514049,
                     message => q|Wobject, Delete|
                   },
          '619' => {
                     lastUpdated => 1031514049,
                     message => q|This function permanently deletes the selected wobject from a page. If you are unsure whether you wish to delete this content you may be better served to cut the content to the clipboard until you are certain you wish to delete it.
<p>


As with any delete operation, you are prompted to be sure you wish to proceed with the delete. If you answer yes, the delete will proceed and there is no recovery possible. If you answer no you'll be returned to the prior screen.
<p>

|
                   },
          '45' => {
                    lastUpdated => 1031514049,
                    message => q|No, I made a mistake.|
                  },
          '671' => {
                     lastUpdated => 1047858549,
                     message => q|Wobjects, Using|
                   }

};

1;

[Free]  Add New Model IDs

About Resource:
This resource allows you to add new Vehicles, Peds and Object models to your server without replacing existing ones, with consistent IDs shared both client and serverside.  This consistency is even supported in event calls, convenient for  players and devs alike. 

How to Set-up:
  - Add the resource "Chemical_Model_Loader" to the startup list in "server/mods/deathmatch/mtaserver.conf" (highly recommended)
  - Place your mods in the "chemical_mod_loader" resource's "New IDs" or "Replace IDs" folders
  - Start the "chemical_mod_loader" resource and the custom "freeroam" (or load models via your script) resource.

Features:
  - Custom Freeroam resource that update custom models as they are added (or removed) automatically!
  - Easily add new Ped skins, Car mods and Object models to your server, just drag, drop, reset, done!
  - Automatically Load Data - such as; Handling, Colors, Wheel Size - for your vehicle mods, pulled from .txt/.dat/.ide/.cfg files and applied (simple place the text file with the info in the same folder, done!)
	Note - that Carmod data is not natively supported for new models and as such is not currently used
  - Easily replace your default server models like weapons, cars and peds
  - Automatically determine the source id of you new models based on file names or folder names! (see below)

Scripting Support:
  To use the new models in your resource, you will need to import the "import_chemical_models.lua" to your resource.
	- First copy the import script found in Chemical_Model_Loader named "import_chemical_models.lua" to your resource.
	- Next add <include resource="Chemical_Model_Loader"/> to your resource "meta.xml" (or better yet ensure the resource in running on server start-up)
	- Then set the import script to load first in your resource (recomended in 99% use cases) "<script src="import_chemical_models.lua" type="shared" cache="false"/>"
	Doing this should automatically import all the functions of Chemical_Model_Loader you'll need.
	- New Functions: addModelID, removeModelID, getExtraModels, getExtraModelsData

How to Use:
  Simple add your mods in the "New IDs" or "Replace IDs" folders and re/start the resource.
  Add text files (.txt/.dat/.ide/.cfg) within vehicles mod folders to automatically import mod data! (works with replaced models too)
  It is highly recommended that you add you new model in sub-folders (tho files will still be read)

  The following folders (and its sub-folders) will load all models as one type, irrespective of file name:
	"New IDs/_Vehicles" - Loads all as vehicles (I will add support for vehicle upgrade recconition if enough people find the resource useful)
	"New IDs/_Objects" - Loads all as obects
	"New IDs/_Peds" - Loads all as Peds
	NOTE! - Placing incompatible file types may crash the client when the resource starts
	Note!!! - These folders are optional and doesn't have to be used, files outside of these folders will load based on id# or file name to the correct element type (or object if not found)
	  - Files with new names will correctly be loaded as vehicles if its handling data can be found in a .txt/.dat/.ide/.cfg file

  Models will use the property of the base_id or (source id) they are named after (ie infernus.dff/411.dff will load with the handling of the Infernus unless a .txt file is used)
	- You can specify the base_id of all files in a folder by ending it with the desired base_id in brackets ie: "Fast Cars (411)" or "Nice Cars (Sultan)"
	- This effect also applies the files in its sub-folder and can be reverted to normal with empty brackets ie: "Other Cars ()"

  The Name and id_name of the new model in mta is based on the file_name, folder_name and/or if the name is already taken.
	- ie: file="New IDs/Fast Cars (411)/Jester.dff" -- id_name="fast_cars_jester" -- name="Fast Cars (Jester)"  ------ Note the base_id will not be in the name
	- ie: file="New IDs/Banshee.dff" --  id_name="banshee_1" -- name="Banshee (1)"  ------ Note that the number is because banshee is already a default model


Future Features:
  Car Mods support for new vehicles - Allow the use of car mods on new vehicles
  Vehicle Specific mods - Support unique car mods for new vehicles
  Animation Files import - Automatically add or replace player .ifp
  Mod Manager Menu - For setting the id_name and id_number of new models
  Vehicle Functions support - Support for Folding headlights etc on new models


How to Help:
Join the Discord - discord.com/invite/FxHCc7j
Donate to Projects - kofi.com/chemicalcreations

I'm working on New Weapon IDs as well, with easy customization for sounds, effects, animations, multi-weapon dual wielding and more.


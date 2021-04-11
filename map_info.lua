local match
match = rex.match
Map.help = {
  "<cyan>Nodeka Map Script<reset>\n\n    This script allows for semi-automatic mapping using the included triggers.\n    The script locates the room name by searching up from the detected exits\n    line until a prompt is found or it runs out of text to search, clearing\n    saved text each time a prompt is detected or a movement command is sent.\n    Information on each command or event is available in individual help files.\n\n    <cyan>Fundamental Commands:<reset>\n        These are commands used to get the mapper functional on a basic level\n\n        <yellow>map show<reset> - Displays or hides a map window\n        <yellow>map basics<reset> - Shows a quick-start guide with some basic information to\n            help get the script working\n        <yellow>map help <optional command name><reset> - Shows either this help file or the\n            help file for the command given\n        <yellow>map debug<reset> - Toggles on debug mode, in which extra messages are shown\n            with the intent of assisting in troubleshooting getting the\n            script setup\n        <yellow>map me<reset> - Locates the user on the map, if possible\n        <yellow>map character <name><reset> - Sets a given name as the current character for\n            the purposes of the script, used for different prompt patterns\n            and recall locations\n        <yellow>map recall<reset> - Sets the current room as the recall location of the\n            current character\n\n    <cyan>Mapping Commands:<reset>\n        These are commands used in the process of actually creating a map\n\n        <yellow>map start <optional area name><reset> - Starts adding content to the\n            map, using either the area of the room the user is currently in,\n            or the area name provided\n        <yellow>map stop<reset> - Stops adding content to the map\n        <yellow>map area <area name><reset> - Moves the current room to the named area\n        <yellow>map mode <simple, normal, or complex><reset> - Sets the mapping mode\n        <yellow>map door <direction> <door name> <optional locked 'yes' or 'no'><reset> -\n            Creates a door in the given direction, with the given status (default unlocked)\n        <yellow>map shift <n|e|s|w|u|d><reset> - Moves the current room on the map in the given\n            direction\n        <yellow>map merge<reset> - Combines overlapping rooms that have the same name into\n            a single room\n        <yellow>map clear moves<reset> - Clears the list of movement commands maintained by the\n            script\n        <yellow>map store<reset> - Stores the current room for use with 'map exit'\n        <yellow>map exit <direction> <optional roomID><reset> - Creates an exit in the given\n            direction to the room with the specified roomID, can also be used or automatically\n            links with the roomID stored with 'map store'\n        <yellow>map tag <tag><reset> - Tags the room with a unique tag for use with the 'go <tag>' alias.\n            Non-numeric tags only as 'go <number>' assumes a room number.\n        <yellow>map multitag <tag><reset> - Tags the room with a non-unique tag that the 'go <tag>'\n            alias will use to go to the closest room with the matching tag\n        <yellow>map untag <tag name> <optional room ID><reset> Removes the given tag from all rooms or the specific\n            room provided.\n        <yellow>map areas<reset> - Shows a list of all area, with links to show a list of\n            rooms in the area\n        <yellow>map rooms <area name><reset> - Shows a list of rooms in the named area\n\n    <cyan>Sharing and Backup Commands:<reset>\n\n        <yellow>map save <optional file path><reset> - Creates a backup of the map\n        <yellow>map load <optional file path><reset> - Loads a map backup, or a map file from a\n            remote address\n        <yellow>map export <area name><reset> - Creates a file from the named area that can\n            be shared\n        <yellow>map import <area name><reset> - Loads an area from a file\n\n    <cyan>Mapping Events:<reset>\n        These events are used by triggers to direct the script's behavior\n\n        <yellow>onNewRoom<reset> - Signals that a room has been detected, optional exits\n            argument\n        <yellow>onMoveFail<reset> - Signals that an attempted move failed\n        <yellow>onForcedMove<reset> - Signals that the character moved without a command\n            being entered, required direction argument\n\n    <cyan>Key Variables:<reset>\n        These variables are used by the script to keep track of important\n            information\n\n        <yellow>Map.prompt.room<reset> - Can be set to specify the room name\n        <yellow>Map.prompt.exits<reset> - Can be set to specify the room exits\n        <yellow>Map.character<reset> - Contains the current character name\n        <yellow>Map.save.recall<reset> - Contains a table of recall roomIDs for all\n            characters\n        <yellow>Map.configs<reset> - Contains a number of different options that can be set\n            to modify script behavior\n        <yellow>Map.currentRoom<reset> - Contains the roomID of the room your character is\n            in, according to the script\n        <yellow>Map.currentName<reset> - Contains the name of the room your character is in,\n            according to the script\n        <yellow>Map.currentExits<reset> - Contains a table of the exits of the room your\n            character is in, according to the script\n        <yellow>Map.currentArea<reset> - Contains the areaID of the area your character is\n            in, according to the script"
}
Map.help.save = "<cyan>Map Save<reset>\n        syntax: <yellow>map save <optional file path><reset>\n\n        This command creates a copy of the current map and stores it in the\n        profile folder as Map.dat or at the specified path. This can be useful\n        for creating a backup before adding new content, in case of problems,\n        and as a way to share an entire map at once."
Map.help.load = "<cyan>Map Load<reset>\n        syntax: <yellow>map load <optional file path><reset>\n\n        This command replaces the current map with the map stored as Map.dat in\n        the profile folder. Alternatively, if a file path is provided, a map is\n        loaded from that location to replace the current Map. If no\n        filename is given with the download address, the script tries to\n        download Map.dat. If a filename is given it MUST end with .dat."
Map.help.show = "<cyan>Map Show<reset>\n        syntax: <yellow>map show<reset>\n\n        This command shows a map window, as specified by the window configs."
Map.help.export = "<cyan>Map Export<reset>\n        syntax: <yellow>map export <area name><reset>\n\n        This command creates a file containing all the information about the\n        named area and stores it in the profile folder, with a file name based\n        on the area name. This file can then be imported, allowing for easy\n        sharing of single map areas. The file name will be the name of the area\n        in all lower case, with spaces replaced with underscores, and a .dat\n        file extension."
Map.help.import = "<cyan>Map Import<reset>\n        syntax: <yellow>map import <area name><reset>\n\n        This command imports a file from the profile folder with a name matching\n        the name of the file, and uses it to create an area on the Map. The area\n        name used can be capitalized or not, and may have either spaces or\n        underscores between words. The actual area name is stored within the\n        file, and is not set by the area name used in this command."
Map.help.start_mapping = "<cyan>Start Mapping<reset>\n        syntax: <yellow>map start <optional area name><reset>\n\n        This command instructs the script to add new content to the map when it\n        is seen. When first used, an area name is mandatory, so that an area is\n        created for new rooms to be placed in. If used with an area name while\n        the map shows the character within a room on the map, that room will be\n        moved to be in the named area, if it is not already in it. If used\n        without an area name, the room is not moved, and mapping begins in the\n        area the character is currently located in."
Map.help.stop_mapping = "<cyan>Stop Mapping<reset>\n        syntax: <yellow>map stop<reset>\n\n        This command instructs the script to stop adding new content until\n        mapping is resumed at a later time. The map will continue to perform\n        other functions."
Map.help.debug = "<cyan>Map Debug<reset>\n        syntax: <yellow>map debug<reset>\n\n        This command toggles the map scripts debug mode on or off when it is\n        used. Debug mode provides some extra messages to help with setting up\n        the script and identifying problems to help with troubleshooting. If you\n        are getting assistance with setting up this script, using debug mode may\n        make the process faster and easier."
Map.help.areas = "<cyan>Map Areas<reset>\n        syntax: <yellow>map areas<reset>\n\n        This command displays a linked list of all areas in the Map. When\n        clicked, the rooms in the selected area will be displayed, as if the\n        map rooms command had been used with that area as an argument."
Map.help.rooms = "<cyan>Map Rooms<reset>\n        syntax: <yellow>map rooms <area name><reset>\n\n        This command shows a list of all rooms in the area, with the roomID and\n        the room name, as well as a count of how many rooms are in the area\n        total. Note that the area name argument is not case sensitive."
Map.help.set_area = "<cyan>Set Area<reset>\n        syntax: <yellow>map set area <area name><reset>\n\n        This command move the current room into the named area, creating the\n        area if needed."
Map.help.mode = "<cyan>Map Mode<reset>\n        syntax: <yellow>map mode <simple, normal, or complex><reset>\n\n        This command changes the current mapping mode, which determines what\n        happens when new rooms are added to the Map.\n\n        In simple mode, if an adjacent room has an exit stub pointing toward the\n        newly created room, and the new room has an exit in that direction,\n        those stubs are connected in both directions.\n\n        In normal mode, the newly created room is connected to the room you left\n        from, so long as it has an exit leading in that direction.\n\n        In complex mode, none of the exits of the newly connected room are\n        connected automatically when it is created."
Map.help.add_door = "<cyan>Add Door<reset>\n        syntax: <yellow>map door <direction> <name> <optional locked>\n        <optional yes or no><reset>\n\n        This command places a door on the exit in the given direction, or\n        removes it if none is given as the second argument. The door status is\n        set as given by the second argument, default closed. The third\n        argument determines if the door is a one-way door, default no."
Map.help.shift = "<cyan>Shift<reset>\n        syntax: <yellow>map shift <direction><reset>\n\n        This command moves the current room one step in the direction given, on\n        the Map."
Map.help.merge_rooms = "<cyan>Merge Rooms<reset>\n        syntax: <yellow>map merge<reset>\n\n        This command combines all rooms that share the same coordinates and the\n        same room name into a single room, with all of the exits preserved and\n        combined."
Map.help.clear_moves = "<cyan>Clear Moves<reset>\n        syntax: <yellow>map clear moves<reset>\n\n        This command clears the scripts queue of movement commands, and is\n        intended to be used after you attempt to move while mapping but the\n        movement is prevented in some way that is not caught and handled by a\n        trigger that raises the onMoveFail event."
Map.help.set_exit = "<cyan>Set Exit<reset>\n        syntax: <yellow>map set exit <direction> <destination roomID><reset>\n\n        This command sets the exit in the current room in the given direction to\n        connect to the target room, as specified by the roomID. This is a\n        one-way connection."
Map.help.onnewroom = "<cyan>onNewRoom Event<reset>\n\n        This event is raised to inform the script that a room has been detected.\n        When raised, a string containing the exits from the detected room should\n        be passed as a second argument to the raiseEvent function, unless those\n        exits have previously been stored in Map.prompt.exits."
Map.help.onmovefail = "<cyan>onMoveFail Event<reset>\n\n        This event is raised to inform the script that a move was attempted but\n        the character was unable to move in the given direction, causing that\n        movement command to be removed from the scripts movement queue."
Map.help.onforcedmove = "<cyan>onForcedMove Event<reset>\n\n        This event is raised to inform the script that the character moved in a\n        specified direction without a command being entered. When raised, a\n        string containing the movement direction must be passed as a second\n        argument to the raiseEvent function.\n\n        The most common reason for this event to be raised is when a character\n        is following someone else."
Map.help.onprompt = "<cyan>onPrompt Event<reset>\n\n        This event can be raised when using a non-conventional setup to trigger\n        waiting messages from the script to be displayed. Additionally, if\n        Map.prompt.exits exists and isnt simply an empty string, raising this\n        event will cause the onNewRoom event to be raised as well. This\n        functionality is intended to allow people who have used the older\n        version of this script to use this script instead, without having to\n        modify the triggers they created for it."
Map.help.me = "<cyan>Map Me<reset>\n        syntax: <yellow>map me<reset>\n\n        This command forces the script to look at the currently captured room\n        name and exits, and search for a potentially matching room, moving the\n        map if applicable. Note that this command is generally never needed, as\n        the script performs a similar search any time the room name and exits\n        dont match expectations."
Map.help.character = "<cyan>Map Character<reset>\n        syntax: <yellow>map character <name><reset>\n\n        This command tells the script what character is currently being used.\n        Setting a character is optional, but recall locations and prompt\n        patterns are stored by character name, so using this command allows for\n        easy switching between different setups. The name given is stored in\n        Map.character. The name is a case sensitive exact match. The value of\n        Map.character is not saved between sessions, so this must be set again\n        if needed each time the profile is opened."
Map.help.recall = "<cyan>Map Recall<reset>\n        syntax: <yellow>map recall<reset>\n\n        This command tells the script that the current room is the recall point\n        for the current character, as stored in Map.character. This information\n        is stored in Map.save.recall[Map.character], and is remembered between\n        sessions."
Map.help.quick_start = "<yellow>map basics<reset> (quick start guide)\n    ----------------------------------------\n\n    Nodeka Mapper works in tandem with a script, and this generic mapper script needs\n    to know 2 things to work:\n      - <dim_grey>room name<reset> $ROOM_NAME_STATUS ($ROOM_NAME)\n      - <dim_grey>exits<reset>     $ROOM_EXITS_STATUS ($ROOM_EXITS)\n\n    1. <yellow>map start <optional area name><reset>\n       If both room name and exits are good, you can start mapping! Give it the\n       area name youre currently in, usually optional but required for the first one.\n    2. <yellow>map debug<reset>\n       This toggles debug mode. When on, messages will be displayed showing what\n       information is captured and a few additional error messages that can help\n       with getting the script fully compatible with your game.\n    3. <yellow>map help<reset>\n       This will bring up a more detailed help file, starting with the available\n       help topics."
local map_tag = "<112,229,0>(<73,149,0>map<112,229,0>): <255,255,255>"
local debug_tag = "<255,165,0>(<200,120,0>debug<255,165,0>): <255,255,255>"
local err_tag = "<255,0,0>(<178,34,34>error<255,0,0>): <255,255,255>"
local do_echo
do_echo = function(what, tag)
  moveCursorEnd()
  local curline = getCurrentLine()
  if curline ~= "" then
    echo("\n")
  end
  decho(tag)
  cecho(what)
  echo("\n")
end
Map.echo = function(what, debug, err)
  local tag = map_tag
  if debug then
    tag = tag .. debug_tag
  end
  if err then
    tag = tag .. err_tag
  end
  do_echo(what, tag)
end
Map.error = function(what)
  Map.echo(what, false, true)
end
Map.debug = function(what)
  if Map.config.debug then
    Map.echo(what, true)
  end
end
Map.ShowHelp = function(cmd)
  if cmd == nil then
    cmd = ""
  end
  if cmd and cmd ~= "" then
    if string.starts(cmd, "map ") then
      cmd = {
        cmd = sub(5)
      }
    end
    cmd = string.lower(cmd)
    cmd = string.gsub(cmd, " ", "_")
    if not Map.help[cmd] then
      Map.echo("No help file on that command.")
    end
    Map.echo(Map.help[cmd])
  else
    Map.echo(Map.help[1])
  end
end
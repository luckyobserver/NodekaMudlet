import match from rex
Map.help = {
    "<cyan>Nodeka Map Script<reset>

    This script allows for semi-automatic mapping using the included triggers.
    The script locates the room name by searching up from the detected exits
    line until a prompt is found or it runs out of text to search, clearing
    saved text each time a prompt is detected or a movement command is sent.
    Information on each command or event is available in individual help files.

    <cyan>Fundamental Commands:<reset>
        These are commands used to get the mapper functional on a basic level

        <yellow>map show<reset> - Displays or hides a map window
        <yellow>map basics<reset> - Shows a quick-start guide with some basic information to
            help get the script working
        <yellow>map help <optional command name><reset> - Shows either this help file or the
            help file for the command given
        <yellow>map debug<reset> - Toggles on debug mode, in which extra messages are shown
            with the intent of assisting in troubleshooting getting the
            script setup
        <yellow>map me<reset> - Locates the user on the map, if possible
        <yellow>map character <name><reset> - Sets a given name as the current character for
            the purposes of the script, used for different prompt patterns
            and recall locations
        <yellow>map recall<reset> - Sets the current room as the recall location of the
            current character

    <cyan>Mapping Commands:<reset>
        These are commands used in the process of actually creating a map

        <yellow>map start <optional area name><reset> - Starts adding content to the
            map, using either the area of the room the user is currently in,
            or the area name provided
        <yellow>map stop<reset> - Stops adding content to the map
        <yellow>map area <area name><reset> - Moves the current room to the named area
        <yellow>map mode <simple, normal, or complex><reset> - Sets the mapping mode
        <yellow>map door <direction> <door name> <optional locked 'yes' or 'no'><reset> -
            Creates a door in the given direction, with the given status (default unlocked)
        <yellow>map shift <n|e|s|w|u|d><reset> - Moves the current room on the map in the given
            direction
        <yellow>map merge<reset> - Combines overlapping rooms that have the same name into
            a single room
        <yellow>map clear moves<reset> - Clears the list of movement commands maintained by the
            script
        <yellow>map store<reset> - Stores the current room for use with 'map exit'
        <yellow>map exit <direction> <optional roomID><reset> - Creates an exit in the given
            direction to the room with the specified roomID, can also be used or automatically
            links with the roomID stored with 'map store'
        <yellow>map tag <tag><reset> - Tags the room with a unique tag for use with the 'go <tag>' alias.
            Non-numeric tags only as 'go <number>' assumes a room number.
        <yellow>map multitag <tag><reset> - Tags the room with a non-unique tag that the 'go <tag>'
            alias will use to go to the closest room with the matching tag
        <yellow>map untag <tag name> <optional room ID><reset> Removes the given tag from all rooms or the specific
            room provided.
        <yellow>map areas<reset> - Shows a list of all area, with links to show a list of
            rooms in the area
        <yellow>map rooms <area name><reset> - Shows a list of rooms in the named area

    <cyan>Sharing and Backup Commands:<reset>

        <yellow>map save <optional file path><reset> - Creates a backup of the map
        <yellow>map load <optional file path><reset> - Loads a map backup, or a map file from a
            remote address
        <yellow>map export <area name><reset> - Creates a file from the named area that can
            be shared
        <yellow>map import <area name><reset> - Loads an area from a file

    <cyan>Mapping Events:<reset>
        These events are used by triggers to direct the script's behavior

        <yellow>onNewRoom<reset> - Signals that a room has been detected, optional exits
            argument
        <yellow>onMoveFail<reset> - Signals that an attempted move failed
        <yellow>onForcedMove<reset> - Signals that the character moved without a command
            being entered, required direction argument

    <cyan>Key Variables:<reset>
        These variables are used by the script to keep track of important
            information

        <yellow>Map.prompt.room<reset> - Can be set to specify the room name
        <yellow>Map.prompt.exits<reset> - Can be set to specify the room exits
        <yellow>Map.character<reset> - Contains the current character name
        <yellow>Map.save.recall<reset> - Contains a table of recall roomIDs for all
            characters
        <yellow>Map.configs<reset> - Contains a number of different options that can be set
            to modify script behavior
        <yellow>Map.currentRoom<reset> - Contains the roomID of the room your character is
            in, according to the script
        <yellow>Map.currentName<reset> - Contains the name of the room your character is in,
            according to the script
        <yellow>Map.currentExits<reset> - Contains a table of the exits of the room your
            character is in, according to the script
        <yellow>Map.currentArea<reset> - Contains the areaID of the area your character is
            in, according to the script",
  }
Map.help.save = "<cyan>Map Save<reset>
        syntax: <yellow>map save <optional file path><reset>

        This command creates a copy of the current map and stores it in the
        profile folder as Map.dat or at the specified path. This can be useful
        for creating a backup before adding new content, in case of problems,
        and as a way to share an entire map at once."
Map.help.load = "<cyan>Map Load<reset>
        syntax: <yellow>map load <optional file path><reset>

        This command replaces the current map with the map stored as Map.dat in
        the profile folder. Alternatively, if a file path is provided, a map is
        loaded from that location to replace the current Map. If no
        filename is given with the download address, the script tries to
        download Map.dat. If a filename is given it MUST end with .dat."
Map.help.show = "<cyan>Map Show<reset>
        syntax: <yellow>map show<reset>

        This command shows a map window, as specified by the window configs."
Map.help.export = "<cyan>Map Export<reset>
        syntax: <yellow>map export <area name><reset>

        This command creates a file containing all the information about the
        named area and stores it in the profile folder, with a file name based
        on the area name. This file can then be imported, allowing for easy
        sharing of single map areas. The file name will be the name of the area
        in all lower case, with spaces replaced with underscores, and a .dat
        file extension."
Map.help.import = "<cyan>Map Import<reset>
        syntax: <yellow>map import <area name><reset>

        This command imports a file from the profile folder with a name matching
        the name of the file, and uses it to create an area on the Map. The area
        name used can be capitalized or not, and may have either spaces or
        underscores between words. The actual area name is stored within the
        file, and is not set by the area name used in this command."
Map.help.start_mapping = "<cyan>Start Mapping<reset>
        syntax: <yellow>map start <optional area name><reset>

        This command instructs the script to add new content to the map when it
        is seen. When first used, an area name is mandatory, so that an area is
        created for new rooms to be placed in. If used with an area name while
        the map shows the character within a room on the map, that room will be
        moved to be in the named area, if it is not already in it. If used
        without an area name, the room is not moved, and mapping begins in the
        area the character is currently located in."
Map.help.stop_mapping = "<cyan>Stop Mapping<reset>
        syntax: <yellow>map stop<reset>

        This command instructs the script to stop adding new content until
        mapping is resumed at a later time. The map will continue to perform
        other functions."
Map.help.debug = "<cyan>Map Debug<reset>
        syntax: <yellow>map debug<reset>

        This command toggles the map scripts debug mode on or off when it is
        used. Debug mode provides some extra messages to help with setting up
        the script and identifying problems to help with troubleshooting. If you
        are getting assistance with setting up this script, using debug mode may
        make the process faster and easier."
Map.help.areas = "<cyan>Map Areas<reset>
        syntax: <yellow>map areas<reset>

        This command displays a linked list of all areas in the Map. When
        clicked, the rooms in the selected area will be displayed, as if the
        map rooms command had been used with that area as an argument."
Map.help.rooms = "<cyan>Map Rooms<reset>
        syntax: <yellow>map rooms <area name><reset>

        This command shows a list of all rooms in the area, with the roomID and
        the room name, as well as a count of how many rooms are in the area
        total. Note that the area name argument is not case sensitive."
Map.help.set_area = "<cyan>Set Area<reset>
        syntax: <yellow>map set area <area name><reset>

        This command move the current room into the named area, creating the
        area if needed."
Map.help.mode = "<cyan>Map Mode<reset>
        syntax: <yellow>map mode <simple, normal, or complex><reset>

        This command changes the current mapping mode, which determines what
        happens when new rooms are added to the Map.

        In simple mode, if an adjacent room has an exit stub pointing toward the
        newly created room, and the new room has an exit in that direction,
        those stubs are connected in both directions.

        In normal mode, the newly created room is connected to the room you left
        from, so long as it has an exit leading in that direction.

        In complex mode, none of the exits of the newly connected room are
        connected automatically when it is created."
Map.help.add_door = "<cyan>Add Door<reset>
        syntax: <yellow>map door <direction> <name> <optional locked>
        <optional yes or no><reset>

        This command places a door on the exit in the given direction, or
        removes it if none is given as the second argument. The door status is
        set as given by the second argument, default closed. The third
        argument determines if the door is a one-way door, default no."
Map.help.shift = "<cyan>Shift<reset>
        syntax: <yellow>map shift <direction><reset>

        This command moves the current room one step in the direction given, on
        the Map."
Map.help.merge_rooms = "<cyan>Merge Rooms<reset>
        syntax: <yellow>map merge<reset>

        This command combines all rooms that share the same coordinates and the
        same room name into a single room, with all of the exits preserved and
        combined."
Map.help.clear_moves = "<cyan>Clear Moves<reset>
        syntax: <yellow>map clear moves<reset>

        This command clears the scripts queue of movement commands, and is
        intended to be used after you attempt to move while mapping but the
        movement is prevented in some way that is not caught and handled by a
        trigger that raises the onMoveFail event."
Map.help.set_exit = "<cyan>Set Exit<reset>
        syntax: <yellow>map set exit <direction> <destination roomID><reset>

        This command sets the exit in the current room in the given direction to
        connect to the target room, as specified by the roomID. This is a
        one-way connection."
Map.help.onnewroom = "<cyan>onNewRoom Event<reset>

        This event is raised to inform the script that a room has been detected.
        When raised, a string containing the exits from the detected room should
        be passed as a second argument to the raiseEvent function, unless those
        exits have previously been stored in Map.prompt.exits."
Map.help.onmovefail = "<cyan>onMoveFail Event<reset>

        This event is raised to inform the script that a move was attempted but
        the character was unable to move in the given direction, causing that
        movement command to be removed from the scripts movement queue."
Map.help.onforcedmove = "<cyan>onForcedMove Event<reset>

        This event is raised to inform the script that the character moved in a
        specified direction without a command being entered. When raised, a
        string containing the movement direction must be passed as a second
        argument to the raiseEvent function.

        The most common reason for this event to be raised is when a character
        is following someone else."
Map.help.onprompt = "<cyan>onPrompt Event<reset>

        This event can be raised when using a non-conventional setup to trigger
        waiting messages from the script to be displayed. Additionally, if
        Map.prompt.exits exists and isnt simply an empty string, raising this
        event will cause the onNewRoom event to be raised as well. This
        functionality is intended to allow people who have used the older
        version of this script to use this script instead, without having to
        modify the triggers they created for it."
Map.help.me = "<cyan>Map Me<reset>
        syntax: <yellow>map me<reset>

        This command forces the script to look at the currently captured room
        name and exits, and search for a potentially matching room, moving the
        map if applicable. Note that this command is generally never needed, as
        the script performs a similar search any time the room name and exits
        dont match expectations."
Map.help.character = "<cyan>Map Character<reset>
        syntax: <yellow>map character <name><reset>

        This command tells the script what character is currently being used.
        Setting a character is optional, but recall locations and prompt
        patterns are stored by character name, so using this command allows for
        easy switching between different setups. The name given is stored in
        Map.character. The name is a case sensitive exact match. The value of
        Map.character is not saved between sessions, so this must be set again
        if needed each time the profile is opened."
Map.help.recall = "<cyan>Map Recall<reset>
        syntax: <yellow>map recall<reset>

        This command tells the script that the current room is the recall point
        for the current character, as stored in Map.character. This information
        is stored in Map.save.recall[Map.character], and is remembered between
        sessions."
Map.help.quick_start = "<yellow>map basics<reset> (quick start guide)
    ----------------------------------------

    Nodeka Mapper works in tandem with a script, and this generic mapper script needs
    to know 2 things to work:
      - <dim_grey>room name<reset> $ROOM_NAME_STATUS ($ROOM_NAME)
      - <dim_grey>exits<reset>     $ROOM_EXITS_STATUS ($ROOM_EXITS)

    1. <yellow>map start <optional area name><reset>
       If both room name and exits are good, you can start mapping! Give it the
       area name youre currently in, usually optional but required for the first one.
    2. <yellow>map debug<reset>
       This toggles debug mode. When on, messages will be displayed showing what
       information is captured and a few additional error messages that can help
       with getting the script fully compatible with your game.
    3. <yellow>map help<reset>
       This will bring up a more detailed help file, starting with the available
       help topics."

map_tag = "<112,229,0>(<73,149,0>map<112,229,0>): <255,255,255>"
debug_tag = "<255,165,0>(<200,120,0>debug<255,165,0>): <255,255,255>"
err_tag = "<255,0,0>(<178,34,34>error<255,0,0>): <255,255,255>"
do_echo = (what, tag) ->
    moveCursorEnd!
    curline = getCurrentLine!
    if curline ~= ""
        echo("\n")
    decho(tag)
    cecho(what)
    echo("\n")
    return

Map.echo = (what, debug, err) ->
    tag = map_tag
    if debug then tag ..= debug_tag
    if err then tag ..= err_tag
    do_echo(what, tag)
    return

Map.error = (what) ->
    Map.echo(what,false,true)
    return

Map.debug = (what) ->
    if Map.config.debug
        Map.echo(what,true)
    return

Map.ShowHelp = (cmd="") ->
    if cmd and cmd != ""
        if string.starts(cmd, "map ") then cmd = cmd:sub(5)
        cmd = string.lower(cmd)
        cmd = string.gsub(cmd, " ","_")
        if not Map.help[cmd] then Map.echo("No help file on that command.")
        Map.echo(Map.help[cmd])
    else
        Map.echo(Map.help[1])
    return

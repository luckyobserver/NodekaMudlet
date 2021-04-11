# Nodeka Mudlet Plugin

This project provides a plugin to enable the use of [Mudlet](https://www.mudlet.org/) to play [Nodeka](http://nodeka.com). The plugin provides the following capabilities:

- Bot for automated running
- Crafting functionality
- GUI
	- Overhead Map
	- Interactive World Map
	- Chat window
	- Run stat window
	
## Installation

To use the plugin there are two options:

1. User Mode - Just make it work
2. Developer Mode - I want to modify stuff

### User Mode

User mode is the easiest way to install.

1. Download the `NodekaMudlet.mpackage` from [latest release](https://github.com/luckyobserver/nodekamudlet/releases/latest)
2. Open "Package Manager" from the "Toolbox" menu or push `Alt+O`
3. Click `Install` and navigate to the downloaded `.mpackage`. This will install the package and you should be ready to go.

Note: any changes you make to triggers/scripts etc... will be saved to your Mudlet profile xml file and not back to the module. This makes it difficult to share any changes to your triggers/aliases/scripts.

### Developer Mode

If you want to modify the scripts and contribute to the plugin then you will need to follow a few extra steps.

**Note:** Mudlet uses lua as the scripting language, I chose to develop the scripts in [Moonscript](https://moonscript.org/) as I enjoy writing Moonscript much more than lua. You can either modify the `.lua` scripts directly or use the `.moon` files in the `src` directory. Any pull requests that modify the `.lua` files directly will be translated to the `.moon` files as I overwrite the `.lua` files when I compile. Follow the directions on the Moonscript site to install Moonscript on your machine. I also use 7zip to package the module, so have 7z available as a command. My build script assumes you're on Linux - If someone wants to write a Windows version that would be awesome.

1. Identify your Mudlet home directory.
	1. Open Mudlet and connect to Nodeka.
	2. In the command line type:`lua getMudletHomeDir()` The directory will be printed on the screen.

2. Clone the NodekaMudlet repository to the [MudletHome] directory: `git clone https://github.com/luckyobserver/nodekamudlet.git [MudletHome]/NodekaMudlet`

1. Open the Module manager (`Alt+I`) and navigate to the cloned `NodekaMudlet` directory and select the `NodekaMudlet.xml` file. Check the "sync" box in the Module manager so that any trigger changes are synchronized with the xml file.

Now you can modify any of the `src/*.moon` files and recompile using the `build.sh` script. Once you change the script you can use the command `lua resetProfile()` in Mudlet to reload the changes.

## Usage

There are four main components of the package. 

1. The `Player` component which can be seen in the Mudlet `Alias/Trigger/Script` sections which handles autobuffs, skill/spell specific scripting, followers, etc...
2. The `Map` component which manages the world map.
2. The `Bot` component which handles running around areas and attacking stuff
3. The `Craft` component which manages your crafting inventory and has convenience aliases and scripts for doing trades and looking up crafting info.


### Player Config

The first step will be configuring the script for your specific class. The current script is for Valkyrie because that's my current class - you can see how I've configured buffs etc in the ``NodekaManager/Config Script` in the Mudlet `Scripts` tab.

The Bot uses the 'attack ' alias to attack mobs as it sees them. The 'attack ' alias calls on the `Player.startCombo` as defined in the config to determine which ability to use for the attack. You can either redefine the `attack` alias to always use a certain skill (such as "cast 'fireball'") or to use the combos. 

Setting up the `Player.buffsWanted` array in the `Config Script` will check for the listed abilities from the `Ability List Script` and attempt to keep them running on your character. To add your classes abilities look at how the script is laid out and add your stuff to it.

Currently the plugin needs to be able to detect the following prompts:

1. Non-combat prompt
2. Combat prompt
3. Pool prompt

My prompt string looks like this:

```
$i[$T:$t][$O:$o][$L]$R$i$I[Reply:$r][Xp:$x][A:$a][G:$g][$L][$p]$R$I[H:$h/$H][M:$m/$M][S:$s/$S][E:$e/$E]
```

Resulting in this prompt:

```
Normal:
[Reply:][Xp:1677153610][A:-1000][G:107687077][1000][]
[H:55709/63638][M:48320/50095][S:10652/10652][E:43138/43146]

Combat:
[Artur:(slightly scratched)][archer:(near death)][2000]
[H:55709/63638][M:48391/50095][S:10652/10652][E:43138/43146]
```

### Map Usage

The Map is a world map for Nodeka and tracks your character as you move around. Use `map help` to see some of the commands available for mapping but the basics are this:

#### Initialization
1. Set your character using `map character <name>`
2. Set your recall by walking to your recall room and typing `map recall`

#### Adding to the map
1. `map start` causes the map to enter edit mode and lets you add rooms, doors, and areas to the world map. You do this by moving around the world, opening and closing doors, etc... Once you're done mapping a section type `map stop` and `map save` and it will back up your current map and save your new changes.
2. If you want to add a new area to a map, for example your clan hall, enter the first room of your clan hall off the continent or wherever you connect and type `map start <area name>`. You will see a new area started on the map window and you can walk around adding rooms.
3. Use `map save` and `map load` often when mapping if there is an error. If you're mapping and something gets jacked up then type `map load` and it will load your last save. So don't save unless you know what you've mapped is good.

### Bot Usage

The `Bot` is like Nembot except a little easier to use. It relies heavily on the `Map` component as all paths are auto-generated as you run through an area. There are three prerequisites before the `Bot` will be able to run an area:

1. All rooms in the desired area must be mapped (using `map start <area>`)
2. All desired mobs must have triggers defined in the corresponding Trigger folder (`NodekaMudlet/Bot Triggers/Area Triggers/[Area]`) - See existing triggers for the template.
3. The `Config Script` must have the map area name mapped to the map trigger folder or the script won't be able to enable the mob triggers.

Once you have everything set up to run you simply type `start <room tag or room#>` and the `Bot` will walk to the tagged room and start running. After you kill all the mobs in the room the `Bot` looks for the next closest room you haven't cleared yet and walks there.

To stop running you type `stop` and your last room is saved and the `Bot` stops. To resume your run simply type `start` and the `Bot` will walk back to your last room from wherever you are and pick up right where you left off. If you want to restart you just type `start <room tag or room#>` and it gives you a fresh start.

If you define a repop trigger in the bot triggers for an area it will clear your visited rooms when the area repops.

### Craft Usage

The craft capabilities can be reviewed using the command `#craft help`:

```
Craft Help

The following commands are available from the craft module. For additional info
use #craft help <command> for any highlighted word. Most words can be shortened

#tradescraps                                   - Trade all scraps into components
#craft recipes [class1] [class2] [stats]       - Show recipes filtered by class or stats
#craft slots                                   - Display recipes to make items for each slot
#tradejewels [#]                               - Trade # jewels with Stacy, defaults to 50
#tradecomponents [#] [item]                    - Add item to queue or execute trade
#craft help <command>                          - Display detailed help about a specified command.
#craft reset                                   - Resets craft plugin.
#put[components|scraps|all]                    - Put away items
#craft gemstones                               - Displays gemstone info
#craft components                              - Display component and scrap info
#get<components|scraps> [#] [name]             - Add item to retrieval queue or execute retrieval
```

Before using the craft capabilities you must set the following arrays up to tell the plugin how you want it to be configured:

1. Craft.bags - which bags hold your scraps/comps
2. Craft.tradeAny - which comps you want to use as fodder when trading
3. Craft.startLow - do you want to use up low value comps first or high value comps first
4. Craft.useSmile - do you want to get smiles when you trade or just use the normal value

Once you have the variables set then use the command `#craft init` or `#ci` and the plugin will check your artistry/expertise and bags. After that you can see your crafting inventory using `#craft components` or `#cc`.

Trading is different than UMC in that you define a trade queue of what comps you want and then kick the trades off. The plugin automatically uses components defined by the `Craft.tradeAny` variable to trade for the target components and does all the trades for you. It handles getting smiles automatically, but if you have re-initialized and already have smiles you need to set it by hand otherwise it will re-do getting smiles. Use the `#css <#>` to set your smile number.

Put comps/scraps away using the `#putc #puts or #puta` commands (`#puta` puts both types away). This won't work until you've initialized.

Use the `#craft slots` or `#csl` command to view what slots you can craft items for.

Use the `#craft recipes` or `#cr` command to view recipe types, append an argument to filter the list for a certain stat or class.

Use the `#craft gemstones` or `#cg` command to view your gemstones.

Get scraps/comps using `#getscraps/#getcomponents/#gets/#getc # [name]`

Trade all your scraps for comps using `#tradescraps` which will keep looping until you have no more scraps (doesn't do jewels)

Trade jewels using `#tradejewels [# default 50]`

# Alpha Version
This is an alpha version. I've only ever used it for myself so we will need to work out bugs as new users adapt it to their character. Pull requests are welcome!

Thanks,

Artur
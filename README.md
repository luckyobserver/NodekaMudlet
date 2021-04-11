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

1. Download the [latest release](https://github.com/luckyobserver/nodekamudlet/releases/latest)
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
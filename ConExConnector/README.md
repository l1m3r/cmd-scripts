
# ConExConnector.cmd - the Conan Exiles (server) Connector

Join your favorite servers directly with the correct list of mods and let this script keep track of said 'modlist.txt'.

Tags: 

---

## Features

- Connect to servers with the correct modlist and thus without the need for Conan to restart itself.
- Reads the configuration (IP, password, etc.) from config files (one per server).
- Saves the current/last modlist with an autogenerated name where the script itself resides. (*)
- Speeds up Conans startup by disabling the intro clips/movies/videos. (*)
- Starts Conan with `abovenormal` priority. (*)

Features marked with (*) can be controlled individually in the config file for each server.

---

## Installation

__still2do__

- RAW download links.
- Images of what it should look like

---

## Usage

__still2do__

- Copy `Example.CECcfg` and fill that copy with the necessary information for one server.
- drag'n'drop CECcfg file on the cmd-script to open it.
OR
- create link to cmd-script and add the path to CECcfg.

---

## Limitations

- This script doesn't manage the mods by itself nor does it fetch them for you.
  You still need to use/allow Steam / Conan Exiles to select/manage/update them.
  It only keeps track of the modlist __after__ it was created/modified by Conan Exiles, so Conan still restarts itself the first time you connect and once every time the server changed it's modlist.
- If your Conan isn't in the default Steam-library folder this script will most likely not find it and you'd need to set the proper path in your config files.


---

## Notes

The script
- is untested with BattleEye since I don't use it.
- may depend on the OS language to work. So far it seems to work in English and German Windows without modifications.
- has only been tested a bit on Windows 8.1 and 10.

---

## Contributing

- Let me know if it works with BattleEye and with other Windows languages.


### Step 1

- **Option 1**
    - 🍴 Fork this repo!

- **Option 2**
    - 👯 Clone this repo to your local machine.

### Step 2

- **HACK AWAY!** 🔨🔨🔨

### Step 3

- 🔃 Create a new [pull request](https://github.com/l1m3r/cmd-scripts/compare/).


---

## FAQ

No Q&As so far.


---

## License

see LICENSE.md in the root folder of this repo.
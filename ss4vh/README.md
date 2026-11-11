# SSound4Val.cmd - Surround sound for Valheim & more

Choose and change Valheim's surround sound configuration to your hearts desire.

Optionally add some GFX configuration options to VH's `boot.config` and switch VH's (keyboard) input method between '***normal***' - respecting the users keyboard layout & language - and '***physical***' - using Unity/hardware [key-codes](https://docs.unity3d.com/ScriptReference/KeyCode.html) instead.

---

## Features

- Reads Valheim's current speaker/input configuration and lets you change it.
- If it can't find the file to patch you can drag'n'drop it manually on the script file(!) instead (not on the running cmd shell window).

---

## Usage

- Download the latest master branch [SSound4Val.cmd](https://github.com/l1m3r/cmd-scripts/raw/master/ss4vh/SSound4Val.cmd) (right click, *save as*).
- Run it & follow the instructions.

**Optionally:**

* This script can download the required 3rd party program [sfk.exe](http://stahlworks.com/dev/sfk/sfk.exe) on its own but you can download and [check/verify](https://www.virustotal.com/gui/file/41a48f6219888e35f0e56f6f97fd2c960eb4c1fe8ed1434a62cc22ee21e107c7/detection/f-41a48f6219888e35f0e56f6f97fd2c960eb4c1fe8ed1434a62cc22ee21e107c7-1683457704)(v1.9.8.2) it separately if you don't trust it (save it in the same folder or anywhere in `%PATH%`).

---

## How it works

This script uses [Swiss File Knife](http://www.stahlworks.com/swiss-file-knife.html) to modify half-a-byte in the file `...\Valheim\valheim_Data\globalgamemanagers` (no extension). It replaces Valheim's default value of `2` for Unity's [AudioSpeakerMode](https://docs.unity3d.com/ScriptReference/AudioSpeakerMode.html) with 

| Hex value | Speaker                 |
| --------- | ----------------------- |
| 1         | Mono                    |
| 2         | Stereo                  |
| 3         | Quadraphonic            |
| 4         | Surround 5.0            |
| 5         | Surround 5.1            |
| 6         | Surround 7.1            |
| 7         | Prologic *(not tested)* |
| d         | Surround 7.1.4 *(not tested)* |

**Alternatively one can**

- install the mod [SimpleAudioOptions ](https://thunderstore.io/c/valheim/p/Azumatt/SimpleAudioOptions/) instead.

- use [UABEA](https://github.com/nesrak1/UABEA) to edit the file directly (but for some reason leave a few more bytes modified).

- use any hex-editor to modify it manually (see the [*source*](https://github.com/search?q=repo%3Al1m3r%2Fcmd-scripts+path%3Ass4vh%2FSSound4Val.cmd+hex_Speaker&type=code) for a *usable* hex search string).

- find a way to [get IronGate to just enabled surround sound](https://valheimbugs.featureupvote.com/suggestions/271742/enable-surround-sound-51-71) support in VH which technically existed since its first release (at least).

Changing the input method is handled practically the same.

---

## Limitations

- only works on Windows...
- every update to VH seems to replace the relevant file. -> need to apply the patch after every update (maybe a *proper* mod using BepInEx would be better?).
- *My* hex search strings have worked flawlessly with at least all VH versions between January 2023 and October 2026 but there's no guaranty they will keep doing so in the future.

---

## Notes

The script

- may depend on the OS language to work. So far it seems to work in English and German Windows without modifications.
- has only been tested on Windows 10.

-> Please give feedback on that ^^.

Further reading / documentation / information:

* Iron Gate's / Valheim's [Official feature request](https://valheimbugs.featureupvote.com/suggestions/271742/enable-surround-sound-51-71).

* Steam forum - [5.1 Surround Sound in Valheim?](https://steamcommunity.com/app/892970/discussions/2/3409804177167822291/)

* Reddit - [Finally it is here - after almost two years of waiting real surround sound works](https://www.reddit.com/r/valheim/comments/10ni8cm/finally_it_is_here_after_almost_two_years_of/)

* Reddit - [Key "OemBackslash" unusable in versions (0.217.28,) 0.217.29 & 0.217.30](https://www.reddit.com/r/valheim/comments/17w3des/)

---

## Contributing

### Step 1

- **Option 1**
  
  - Fork this repo!

- **Option 2**
  
  - Clone this repo to your local machine.

### Step 2

- **HACK AWAY!**

### Step 3

- Create a new [pull request](https://github.com/l1m3r/cmd-scripts/compare/).

---

## FAQ

No Q&As so far.

---

## Legal

As far as I can tell nothing in this project and nothing I did to produce it violates any law or license (copyright, IP, EULA, etc.).

And it seems to me like it would fall under "fair use" anyway because the *purposes is interoperability*(!) between Valheim and any setup with more than two speakers. Or to [correct](https://www.lexology.com/library/detail.aspx?g=f5b1193c-f423-4f96-bca5-03f5145ecf15) [errors](https://uk.practicallaw.thomsonreuters.com/w-030-8064?contextData=(sc.Default)&transitionType=Default&firstPage=true).

**Provided as-is. Use at your own risk! No warranty. I disclaim any and all liability.**

---

## License

see [LICENSE.md](../LICENSE.md) in the root folder of this repo.

---

Tags: mod, modification, patch, hack, 3D, surround sound, spatial audio

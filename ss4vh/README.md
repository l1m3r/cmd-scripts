# SSound4Val.cmd - Surround sound for Valheim

Choose and change Valheim's surround sound configuration to your hearts desire.

Tags: 

---

## Features

- Reads Valheim's current speaker configuration and lets you change it.

---

## Usage

- Download the latest master branch [SSound4Val.cmd](https://github.com/l1m3r/cmd-scripts/raw/master/ss4vh/SSound4Val.cmd) (right click, *save as*).
- Run it & follow the instructions.

**Optionally:**

* This script can download the required 3rd party program [sfk.exe](http://stahlworks.com/dev/sfk/sfk.exe) on its own but you can download and [check/verify](https://www.virustotal.com/gui/file/41a48f6219888e35f0e56f6f97fd2c960eb4c1fe8ed1434a62cc22ee21e107c7/detection/f-41a48f6219888e35f0e56f6f97fd2c960eb4c1fe8ed1434a62cc22ee21e107c7-1683457704)(v1.9.8.2) it separately if you don't trust it (save it in the same folder).

---

## How it works

This script uses [Swiss File Knife](http://www.stahlworks.com/swiss-file-knife.html) to modify half-a-byte in the file `...\Valheim\valheim_Data\globalgamemanagers` (no extension). It replaces Valheim's default value of "2" for Unity's [AudioSpeakerMode](https://docs.unity3d.com/ScriptReference/AudioSpeakerMode.html) with 4, 5, 6 or 8 for the respective number of speakers (4, 5, 5.1, 7.1). That's it.

Alternatively one can

- use [UABEA](https://github.com/nesrak1/UABEA) to edit the file directly (but for some reason leave a few more bytes modified).

- use any hex-editor to modify it manually (see the *source* for a *usable* hex search string).

- find a way to get IronGate to just enabled surround sound support in VH which existed since its first release (at least).

---

## Limitations

- only works on Windows...
- every update to VH seems to replace the relevant file. -> need to apply the patch after every update.
- My hex search string has worked flawlessly at least with all VH versions between January and May 2023 but there's no guaranty it will keep doing so in the future.

---

## Notes

The script

- may depend on the OS language to work. So far it seems to work in English and German Windows without modifications.
- has only been tested a bit on Windows 8.1 and 10.

-> Please give feedback on that ^^.

Further reading / documentation / information:

* Iron Gate's / Valheim's [Official feature request](https://valheimbugs.featureupvote.com/suggestions/271742/enable-surround-sound-51-71).

* Steam forum - [5.1 Surround Sound in Valheim?](https://steamcommunity.com/app/892970/discussions/2/3409804177167822291/)

* Reddit - [Finally it is here - after almost two years of waiting real surround sound works](https://www.reddit.com/r/valheim/comments/10ni8cm/finally_it_is_here_after_almost_two_years_of/)

---

## Contributing

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

## Legal

As far as I can tell nothing in this project and nothing I did to produce it violates any law or license (copyright, IP, EULA).

And it seems to me like it would fall under "fair use" anyway because the *purposes is interoperability*(!) between Valheim and any setup with more than two speakers. Or to [correct](https://www.lexology.com/library/detail.aspx?g=f5b1193c-f423-4f96-bca5-03f5145ecf15) [errors](https://uk.practicallaw.thomsonreuters.com/w-030-8064?contextData=(sc.Default)&transitionType=Default&firstPage=true).

---

## License

see [LICENSE.md](../LICENSE.md) in the root folder of this repo.
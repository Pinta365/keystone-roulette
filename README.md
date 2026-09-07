# Keystone Roulette - World of Warcraft Addon

Tired of endless debates about which Mythic+ dungeon to run? Let fate decide with **Keystone Roulette**!

![Image of the keystone roulette](https://cdn.pinta.land/ksr/ksr.png)

![Image of the keystone roulette GUI](https://cdn.pinta.land/ksr/ksrgui.png)

## Description

Keystone Roulette adds a bit of excitement to your Mythic+ runs by randomly selecting a keystone from your party members.
Type `/ksr` to open the GUI to roulette for a keystone to run or simply type `/ksr roll` or `/ksr roulette` to roll without GUI, and the addon will:

* Gather keystone information from everyone in your group.
* Choose a keystone at random.
* Announce the chosen dungeon in party chat, along with a fun, randomized message.
* List all available keystones for transparency.

No more arguments, no more indecision – just pure, unadulterated dungeon-running fun!

## Download

You can download Keystone Roulette from these popular sources:

* [Wago Addons](https://addons.wago.io/addons/keystone-roulette)
* [CurseForge](https://www.curseforge.com/wow/addons/keystone-roulette) 

## Slash Commands

Keystone Roulette offers the following slash commands:

* `/ksr`: Opens the roulette GUI to visually roll for a keystone.
* `/ksr roll`, `/ksr roulette`:  Rolls for a random keystone from your party.
* `/ksr peek`, `/ksr open`: Sends an emote showing all available keystones in your group.
* `/ksr options`: Opens the addon's options panel.
* `/ksr help`: Displays a help message with usage instructions.
* `/ksr debug`: Toggles debug mode.
* `/ksr reset`: Resets the addon settings to their defaults and reloads the UI.

### Limiting the key level

Rolls and votes accept an optional key level range, so you don't roll a +2 when the group wants to push. The range applies to that command only – nothing is saved.

* `/ksr roll +10`: Only rolls keys +10 and above.
* `/ksr roll +10-15`: Only rolls keys +10 through +15.
* `/ksr roll +0-15`: Only rolls keys +15 and below.
* `/ksr vote +10-15`: Same range applied to a vote.
* `/ksr vote 30 +10-15`: A 30 second vote limited to keys +10 through +15.

The GUI has the same thing: **min** and **max** boxes above the buttons that apply to the next Roulette or Start Vote. Keys outside the range are greyed out in the key list so you can see what you're excluding. Leave the boxes blank to include every key.

If no key in the group falls inside the range, the addon says so and lists the key levels the group actually has. `/ksr peek` is never filtered – it always shows every key in the group.

## Troubleshooting

If you encounter any issues, try these steps:

* **Type `/ksr reset`:** This will reset the addon settings to defaults, which might resolve some problems.
* **Check for error messages:** Pay attention to any error messages in the chat frame, as they might provide clues about the issue.

## Debugging and Reporting Issues

To help diagnose problems, Keystone Roulette has a debug mode that provides more detailed information. Here's how to enable it and report issues:

1. **Enable debug mode:** Type `/ksr debug` in the chat frame. This will enable debug messages, which might reveal the cause of the issue. **Note:** While debug mode is enabled, messages will be printed to the console/chat window instead of the party chat.

2. **Reproduce the error:** Try to reproduce the error you're experiencing while debug mode is enabled.

3. **Gather debug output:** Look for debug messages in your chat window. These messages might contain clues about the problem.

4. **Report the issue:** If you're still unable to resolve the issue, please open an issue on the [GitHub repository](https://github.com/Pinta365/keystone-roulette/issues) and include the following information:
    * A description of the issue.
    * Steps to reproduce the error.
    * Any relevant debug output.

By providing this information, you'll help me identify and fix bugs more efficiently, making Keystone Roulette even better!
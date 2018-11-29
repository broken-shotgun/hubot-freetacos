hubot-freetacos
==============

Give (or take away) tacos from Slack users, all from the comfort of your personal Hubot.

[the official repository](https://github.com/broken-shotgun/hubot-freetacos)

API
---

* `@name :taco:` - add a taco to `@name` (must be user)
* `+:taco:` - add a taco from source of previous message
* `@name :poop:` - remove a taco from `@name` (must be user)
* `+:poop:` - remove a taco from source of previous message
* `hubot erase-tacos @name` - erase tacos from scoreboard for `@name` (permanently deletes thing from memory)
* `hubot top-tacos 10` - show the top 10, with a graph of taco counts
* `hubot bottom-tacos 10` - show the bottom 10, with a graph of taco counts
* `hubot tacos @name` - check the taco count for `@name`

New: added support for taco/poop reactions!

Uses Hubot brain.

## Installation

Run the following command

    $ npm install hubot-freetacos

Then to make sure the dependencies are installed:

    $ npm install

To enable the script, add a `hubot-freetacos` entry to the `external-scripts.json`
file (you may need to create this file).

    ["hubot-freetacos"]

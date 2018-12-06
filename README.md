hubot-freetacos
==============

Give (or take away) tacos from Slack users, all from the comfort of your personal Hubot.

[the official repository](https://github.com/broken-shotgun/hubot-freetacos)

API
---

* `@name :taco:` - add a taco (up to 5) to `@name` (must be user)
* `@name :tacobell:` - add 5 tacos to `@name` (must be user)
* `@name :poop:` - remove a taco (up to 5) from `@name` (must be user)
* `@name :poop_fire:` - minus 5 tacos to `@name` (must be user)
* `hubot erase-tacos @name` - erase tacos from scoreboard for `@name` (permanently deletes thing from memory)
* `hubot top-tacos 10` - show the top 10, with a graph of taco counts
* `hubot bottom-tacos 10` - show the bottom 10, with a graph of taco counts
* `hubot tacos @name` - check the taco count for `@name`

Uses Hubot brain.

## Installation

Run the following command

    $ npm install hubot-freetacos

Then to make sure the dependencies are installed:

    $ npm install

To enable the script, add a `hubot-freetacos` entry to the `external-scripts.json`
file (you may need to create this file).

    ["hubot-freetacos"]

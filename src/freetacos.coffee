# Description:
#   The taco giveth and the poop taketh away.
#
# Dependencies:
#   "underscore": ">= 1.0.0"
#   "clark": "0.0.6"
#   "hubot-slack": ">= 4.5.1"
#
# Configuration:
#
# Commands:
#   @name :taco: - gives a taco to @name (limit 5 at a time, can mention multiple users)
#   @name :poop: - removes a taco from @name (limit 5 at a time, can mention multiple users)
#   hubot tacos @name - give current taco count for @name
#   hubot top-tacos <amount> - top <amount>
#   hubot bottom-tacos <amount> - bottom <amount>
#   hubot erase-tacos @name
#
# Author:
#   KingOfBananas
#   ajacksified (for creating hubot-pluslus)
#

_ = require('underscore')
clark = require('clark')

class ScoreKeeper
  constructor: (@robot) ->
    storageLoaded = =>
      @storage = @robot.brain.data.freeTacos ||= {
        scores: {}
        log: {}
        last: {}
      }
      if typeof @storage.last == "string"
        @storage.last = {}

      @robot.logger.debug "Free Tacos Data Loaded: " + JSON.stringify(@storage, null, 2)
    @robot.brain.on "loaded", storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  getUser: (user) ->
    @storage.scores[user] ||= 0
    user

  saveUser: (user, from, room) ->
    @saveScoreLog(user, from, room)
    @robot.brain.save()
    [@storage.scores[user]]

  add: (user, from, room, amount) ->
    if @validate(user, from)
      user = @getUser(user)
      @storage.scores[user] += amount
      @saveUser(user, from, room)
    else
      null

  subtract: (user, from, room, amount) ->
    if @validate(user, from)
      user = @getUser(user)
      @storage.scores[user] -= amount
      @saveUser(user, from, room)
    else
      null

  erase: (user, from, room) ->
    user = @getUser(user)
    delete @storage.scores[user]
    return true

  scoreForUser: (user) ->
    user = @getUser(user)
    @storage.scores[user]

  saveScoreLog: (user, from, room) ->
    unless typeof @storage.log[from] == "object"
      @storage.log[from] = {}

    @storage.log[from][user] = new Date()
    @storage.last[room] = {user: user}

  last: (room) ->
    last = @storage.last[room]
    if typeof last == 'string'
      [last]
    else
      [last.user]

  isSpam: (user, from) ->
    @storage.log[from] ||= {}

    if !@storage.log[from][user]
      return false

    dateSubmitted = @storage.log[from][user]

    date = new Date(dateSubmitted)
    messageIsSpam = date.setSeconds(date.getSeconds() + 5) > new Date()

    if !messageIsSpam
      delete @storage.log[from][user] #clean it up

    messageIsSpam

  validate: (user, from) ->
    user != from && user != "" && !@isSpam(user, from)

  length: () ->
    @storage.log.length

  top: (amount) ->
    tops = []

    for name, score of @storage.scores
      tops.push(name: name, score: score)

    tops.sort((a,b) -> b.score - a.score).slice(0,amount)

  bottom: (amount) ->
    all = @top(@storage.scores.length)
    all.sort((a,b) -> b.score - a.score).reverse().slice(0,amount)

  normalize: (fn) ->
    scores = {}

    _.each(@storage.scores, (score, name) ->
      scores[name] = fn(score)
      delete scores[name] if scores[name] == 0
    )

    @storage.scores = scores
    @robot.brain.save()

module.exports = (robot) ->
  scoreKeeper = new ScoreKeeper(robot)

  robot.hear ///((?:\:taco\:\s{0,1}|\:poop\:\s{0,1}){1,5})///i, (res) ->
    operator = res.match[1]
    from = res.message.user.id
    room = res.message.room

    # filter mentions to just user mentions
    user_mentions = (mention for mention in res.message.mentions when mention.type is "user")

    # when there are user mentions...
    if user_mentions.length > 0
      # process each mention
      for { id } in user_mentions
        score = if operator.includes(":taco:")
                  amount = operator.split(":taco:").length - 1
                  scoreKeeper.add(id, from, room, amount)
                else
                  amount = operator.split(":poop:").length - 1
                  scoreKeeper.subtract(id, from, room, amount)
        if score?
          res.send "<@#{id}> has #{score} :taco:"

  # react/hearReaction is currently broken for hubot 3.x
  # https://github.com/slackapi/hubot-slack/issues/537
  robot.hearReaction (res) ->
    # res.message is a ReactionMessage instance that represents the reaction Hubot just heard
    if res.message.item_user != undefined
      message_user_id = res.message.user.id
      item_user_id = res.message.item_user.id
      if res.message.type == "added"
        if res.message.reaction == "taco"
          res.send "<@#{message_user_id}> added taco reaction to <@#{item_user_id}>"
        if res.message.reaction == "hankey"
          res.send "<@#{message_user_id}> added poop reaction to <@#{item_user_id}>"
      else if res.message.type == "removed"
        if res.message.reaction == "taco"
          res.send "<@#{message_user_id}> removed taco reaction from <@#{item_user_id}>"
        if res.message.reaction == "hankey"
          res.send "<@#{message_user_id}> removed poop reaction from <@#{item_user_id}>"

  robot.respond /(?:erase-tacos )/i, (res) ->
    from = res.message.user.id
    room = res.message.room

    user = res.envelope.user
    isAdmin = @robot.auth?.hasRole(user, 'freetacos-admin') or @robot.auth?.hasRole(user, 'admin')

    # filter mentions to just user mentions
    user_mentions = (mention for mention in res.message.mentions when mention.type is "user")

    # when there are user mentions...
    if user_mentions.length > 0
      for { id } in user_mentions
        if not @robot.auth? or isAdmin
          erased = scoreKeeper.erase(id, from, room)
        else
          return res.reply "Sorry, you don't have authorization to do that."
        if erased?
          message = "Erased points for <@#{id}>"
          res.send message

  robot.respond /tacos (for\s)?(.*)/i, (res) ->
    # filter mentions to just user mentions
    user_mentions = (mention for mention in res.message.mentions when mention.type is "user")

    # when there are user mentions...
    if user_mentions.length > 0
      for { id } in user_mentions
        score = scoreKeeper.scoreForUser(id)
        reasonString = "<@#{id}> has #{score} :taco:"
        res.send reasonString

  robot.respond /(top-tacos|bottom-tacos) (\d+)/i, (res) ->
    operator = res.match[1]
    amount = parseInt(res.match[2]) || 10
    message = []

    command = ""
    if (operator == "top-tacos")
      command = "top"
    else
      command = "bottom"

    tops = scoreKeeper[command](amount)

    if tops.length > 0
      for i in [0..tops.length-1]
        message.push("#{i+1}. <@#{tops[i].name}> : #{tops[i].score}")
    else
      message.push("No scores to keep track of yet!")

    if(command == "top")
      graphSize = Math.min(tops.length, Math.min(amount, 20))
      message.splice(0, 0, clark(_.first(_.pluck(tops, "score"), graphSize)))

    res.send message.join("\n")

ever = require 'ever'

module.exports = (game, opts) ->
  return new DropPlugin(game, opts)

class DropPlugin
  constructor: (@game, opts) ->
    @body = ever(document.body)
    @enable()

  enable: () ->

    @body.on 'dragover', @dragover = (ev) ->
      ev.stopPropagation()
      ev.preventDefault()

    @body.on 'drop', @drop = (ev) ->
      ev.stopPropagation()
      ev.preventDefault()
      console.log 'drop',ev

  disable: () ->
    @body.removeListener 'dragover', @dragover
    @body.removeListener 'drop', @drop


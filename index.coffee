ever = require 'ever'

module.exports = (game, opts) ->
  return new DropPlugin(game, opts)

class DropPlugin
  constructor: (@game, opts) ->
    if not @game.materials.artPacks?
      throw new Error 'voxel-drop requires voxel-texture-shader with artPacks'

    @packs = @game.materials.artPacks

    @body = ever(document.body)
    @enable()

  enable: () ->

    @body.on 'dragover', @dragover = (ev) ->
      ev.stopPropagation()
      ev.preventDefault()

    @body.on 'drop', @drop = (mouseEvent) =>
      mouseEvent.stopPropagation()
      mouseEvent.preventDefault()
      console.log 'drop',mouseEvent

      files = mouseEvent.target.files || mouseEvent.dataTransfer.files

      console.log 'Dropped',files
      for file in files
        console.log 'Reading dropped',file
        reader = new FileReader()
        ever(reader).on 'load', (readEvent) =>
          return if readEvent.total != readEvent.loaded # TODO: progress bar

          arrayBuffer = readEvent.currentTarget.result

          # add artwork pack
          # TODO: detect different files - .zip = artpack, .png = skin, .js/.coffee = plugin, .mca/=save

          if not mouseEvent.shiftKey
            # start over, replacing all current packs - unless shift is held down (then add to)
            @packs.clear()

          @packs.addPack arrayBuffer, file.name

        reader.readAsArrayBuffer(file)

  disable: () ->
    @body.removeListener 'dragover', @dragover
    @body.removeListener 'drop', @drop


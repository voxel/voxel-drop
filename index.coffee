ever = require 'ever'
require 'string.prototype.endswith' # adds String#endsWith if not available - on Chrome; Firefox has it: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/endsWith

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

        if file.name.endsWith('.zip')
          shouldAppend = mouseEvent.shiftKey
          @loadArtPack(file, shouldAppend)
        else
        # TODO: detect different files - .zip = artpack, .png = skin, .js/.coffee = plugin, .mca/=save
          window.alert "Unrecognized file dropped: #{file.name}. Try dropping a resourcepack/artpack (.zip)"
       
  loadArtPack: (file, shouldAppend) ->
    reader = new FileReader()
    ever(reader).on 'load', (readEvent) =>
      return if readEvent.total != readEvent.loaded # TODO: progress bar

      arrayBuffer = readEvent.currentTarget.result

      # add artwork pack

      if not shouldAppend
        # start over, replacing all current packs - unless shift is held down (then add to)
        @packs.clear()

      @packs.addPack arrayBuffer, file.name
      @game.showAllChunks()  # TODO: fix refresh textures
      # TODO: refresh items too? inventory-window

    reader.readAsArrayBuffer(file)

  disable: () ->
    @body.removeListener 'dragover', @dragover
    @body.removeListener 'drop', @drop


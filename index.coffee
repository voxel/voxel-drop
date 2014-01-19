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

        if file.name.endsWith '.zip' # .zip = artpack
          shouldAppend = mouseEvent.shiftKey
          @loadArtPack file, shouldAppend
        else if file.name.endsWith '.js' # .js = script
          @loadScript file
        else
          # TODO: detect different files - .png = skin, .js/.coffee = plugin, .mca/=save
          # TODO: or by file magic headers?
          window.alert "Unrecognized file dropped: #{file.name}. Try dropping a resourcepack/artpack (.zip)"

  readAll: (file, cb) ->
    reader = new FileReader()
    ever(reader).on 'load', (readEvent) =>
      return if readEvent.total != readEvent.loaded # TODO: progress bar

      result = readEvent.currentTarget.result
      cb(result)

    return reader

  readAllText: (file, cb) ->
    (@readAll file, cb).readAsText file

  readAllData: (file, cb) ->
    (@readAll file, cb).readAsArrayBuffer file

  loadScript: (file) ->
    @readAllText file, (text) =>
      # load as plugin
      createPlugin = eval(text)
      name = file.name
      opts = {}

      if not createPlugin
        # didn't return factory constructor, assume not a plugin
        console.log "Ignored non-plugin #{name}, returned #{createPlugin}"
        return

      # TODO: module.exports?

      if not createPlugin.pluginInfo
        console.log "Warning: plugin #{name} missing pluginInfo"

      plugin = @game.plugins.instantiate createPlugin, name, opts
      if not plugin
        window.alert 'Failed to load plugin '+name
      else
        console.log "Loaded plugin: #{name} = #{plugin}"
      
  loadArtPack: (file, shouldAppend) ->
    @readAllData file, (arrayBuffer) =>
      # add artwork pack

      if not shouldAppend
        # start over, replacing all current packs - unless shift is held down (then add to)
        @packs.clear()

      @packs.addPack arrayBuffer, file.name
      @game.showAllChunks()  # TODO: fix refresh textures
      # TODO: refresh items too? inventory-window


  disable: () ->
    @body.removeListener 'dragover', @dragover
    @body.removeListener 'drop', @drop


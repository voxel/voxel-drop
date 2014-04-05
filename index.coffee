ever = require 'ever'
coffee_script = require 'coffee-script'
playerdat = require 'playerdat'

require 'string.prototype.endswith' # adds String#endsWith if not available - on Chrome; Firefox has it: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/endsWith

module.exports = (game, opts) ->
  return new DropPlugin(game, opts)

class DropPlugin
  constructor: (@game, opts) ->
    return if not @game.isClient

    @packs = @game.materials?.artPacks ? @game.plugins?.get('voxel-stitch')?.artpacks
    if not @packs?
      throw new Error 'voxel-drop requires voxel-stitch or voxel-texture-shader with artPacks'

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

        if file.name.endsWith('.zip') or # .zip = artpack
            file.name.endsWith('.jar') # .jar = artpack too, MC jars (TODO: java plugins via doppio?)
          shouldClear = mouseEvent.shiftKey
          @loadArtPack file, shouldClear
        else if file.name.endsWith '.js' # .js = JavaScript 
          @loadScript file
        else if file.name.endsWith '.coffee' # .coffee = CoffeeScript
          @loadScript file
        else if file.name.endsWith '.dat' # .dat = player data file
          shouldAdd = mouseEvent.shiftKey
          @loadPlayerDat file, shouldAdd
        else
          # TODO: detect different files - .png = skin, .mca/=save
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
    @readAllText file, (rawText) =>
      if file.name.endsWith '.coffee'
        text = coffee_script.compile rawText
      else
        text = rawText

      # load as plugin TODO: improve this?
      # TODO: require()'s.. http://wzrd.in/ browserify-as-a-service
      # use Function constructor instead of eval() to control scope
      try
        createCreatePlugin = new Function("
var module = {exports: {}};
var require = #{@game.plugins.require};

#{text}

return module.exports;
")
      catch e
        window.alert "Exception loading plugin #{file.name}: #{e}"
        throw e

      createPlugin = createCreatePlugin()
      name = file.name
      opts = {}

      console.log "loadScript #file.name = #{createPlugin}"

      if not createPlugin or typeof createPlugin != 'function'
        # didn't return factory constructor, assume not a plugin
        console.log "Ignored non-plugin #{name}, returned #{createPlugin}"
        return

      #if not createPlugin.pluginInfo
      #  console.log "Warning: plugin #{name} missing pluginInfo"

      plugin = @game.plugins.instantiate createPlugin, name, opts
      if not plugin
        window.alert 'Failed to load plugin '+name
      else
        console.log "Loaded plugin: #{name} = #{plugin}"
      
  loadArtPack: (file, shouldClear) ->
    @readAllData file, (arrayBuffer) =>
      # add artwork pack

      if shouldClear
        # start over, replacing all current packs - unless shift is held down (then add to)
        @packs.clear()

      @packs.once 'refresh', () =>
        # TODO: listen on proper event instead of guessing timeout
        # see https://github.com/deathcap/voxel-drop/issues/1
        window.setTimeout () =>
          @game.showAllChunks?()
        , 5000
      @packs.addPack arrayBuffer, file.name

      # TODO: refresh items too? inventory-window

  loadPlayerDat: (file, shouldAdd) ->
    @readAllData file, (arrayBuffer) =>
      carryInventory = @game.plugins.get('voxel-carry')?.inventory
      return if not carryInventory?

      playerdat.loadInventory arrayBuffer, (inventory) ->
        if inventory?
          carryInventory.clear() if not shouldAdd # start fresh

          for i in [0...inventory.size()]
            if shouldAdd
              # add anywhere, appending
              carryInventory.give inventory.get(i)
            else
              # copy specific slots, replacing
              carryInventory.set i, inventory.get(i)

  disable: () ->
    @body.removeListener 'dragover', @dragover
    @body.removeListener 'drop', @drop


'use strict';

const playerdat = require('playerdat');

module.exports = (game, opts) => {
  return new DropPlugin(game, opts)
};

module.exports.pluginInfo = {
  loadAfter: ['voxel-stitch']
};

class DropPlugin
{
  constructor(game, opts) {
    this.game = game;

    if (!game.isClient) return;

    if (this.game.materials && this.game.materials.artPacks) {
      this.packs = this.game.materials.artPacks;
    } else if (this.game.plugins.get('voxel-stitch')) {
      this.packs = this.game.plugins.get('voxel-stitch').artpacks;
    }

    if (!this.packs) {
      throw new Error('voxel-drop requires voxel-stitch or voxel-texture-shader with artPacks');
    }

    this.enable();
  }

  enable() {
    document.body.addEventListener('dragover', this.dragover = (ev) => {
      ev.stopPropagation();
      ev.preventDefault();
    });

    document.body.addEventListener('drop', this.drop = (mouseEvent) => {
      mouseEvent.stopPropagation();
      mouseEvent.preventDefault();
      console.log('drop',mouseEvent);

      const files = mouseEvent.target.files || mouseEvent.dataTransfer.files;

      console.log('Dropped',files);
      //for (let file of files) {
      for (let i = 0; i < files.length; ++i) {
        const file = files[i];
        console.log('Reading dropped',file);

        if (file.name.endsWith('.zip') || // .zip = artpack
            file.name.endsWith('.jar')) { //  .jar = artpack too, MC jars (TODO: java plugins via doppio?)
          const shouldClear = mouseEvent.shiftKey;
          this.loadArtPack(file, shouldClear);
        } else if (file.name.endsWith('.js')) { // .js = JavaScript 
          this.loadScript(file);
        } else if (file.name.endsWith('.dat')) { // .dat = player data file
          const shouldAdd = mouseEvent.shiftKey;
          this.loadPlayerDat(file, shouldAdd);
        } else {
          // TODO: detect different files - .png = skin, .mca/=save
          // TODO: or by file magic headers?
          window.alert(`Unrecognized file dropped: ${file.name}. Try dropping a resourcepack/artpack (.zip)`);
        }
      }
    });
  }

  readAll(file, cb) {
    const reader = new FileReader();

    reader.onload = (readEvent) => {
      if (readEvent.total !== readEvent.loaded) {
        return; // TODO: progress bar
      }

      const result = readEvent.currentTarget.result;
      cb(result);
    };

    reader.onerror = (errorEvent) => {
      console.log(errorEvent);
      window.alert(`Error reading file: ${errorEvent}`);
    };

    reader.onabort = (errorEvent) => {
      console.log(errorEvent);
      window.alert(`Aborted reading file: ${errorEvent}`);
    }

    return reader;
  }

  readAllText(file, cb) {
    (this.readAll(file, cb)).readAsText(file);
  }

  readAllData(file, cb) {
    (this.readAll(file, cb)).readAsArrayBuffer(file);
  }

  loadScript(file) {
    this.readAllText(file, (text) => {
      // load as plugin TODO: improve this?
      // TODO: require()'s.. http://wzrd.in/ browserify-as-a-service
      // use Function constructor instead of eval() to control scope
      try {
        const createCreatePlugin = new Function(`
var module = {exports: {}};
var require = ${this.game.plugins.require};

${text}

return module.exports;
`);
      } catch (e) {
        window.alert(`Exception loading plugin ${file.name}: ${e}`);
        throw e;
      }

      const createPlugin = createCreatePlugin();
      const name = file.name;
      const opts = {};

      console.log(`loadScript #file.name = ${createPlugin}`);

      if (!createPlugin || typeof createPlugin !== 'function') {
        // didn't return factory constructor, assume not a plugin
        console.log(`Ignored non-plugin ${name}, returned ${createPlugin}`);
        return;
      }

      //if not createPlugin.pluginInfo
      //  console.log "Warning: plugin #{name} missing pluginInfo"

      const plugin = this.game.plugins.instantiate(createPlugin, name, opts);
      if (!plugin) {
        window.alert('Failed to load plugin '+name);
      } else {
        console.log(`Loaded plugin: ${name} = ${plugin}`);
      }
    });
  }
      
  loadArtPack(file, shouldClear) {
    this.readAllData(file, (arrayBuffer) => {
      // add artwork pack

      if (shouldClear) {
        // start over, replacing all current packs - unless shift is held down (then add to)
        this.packs.clear();
      }

      this.packs.once('refresh', () => {
        // TODO: listen on proper event instead of guessing timeout
        // see https://github.com/deathcap/voxel-drop/issues/1
        window.setTimeout(() => {
          this.game.showAllChunks();
        }, 5000);
      });

      this.packs.addPack(arrayBuffer, file.name);

      // TODO: refresh items too? inventory-window
    })
  }

  loadPlayerDat(file, shouldAdd) {
    this.readAllData(file, (arrayBuffer) => {
      if (!this.game.plugins.get('voxel-carry')) return;

      const carryInventory = this.game.plugins.get('voxel-carry').inventory;

      playerdat.loadInventory(arrayBuffer, (inventory) => {
        if (inventory) {
          if (!shouldAdd) carryInventory.clear(); // start fresh

          for (let i = 0; i < inventory.size; ++i) {
            if (shouldAdd) {
              // add anywhere, appending
              carryInventory.give(inventory.get(i));
            } else {
              // copy specific slots, replacing
              carryInventory.set(i, inventory.get(i));
            }
          }
        }
      });
    });
  }

  disable() {
    this.body.removeListener('dragover', this.dragover);
    this.body.removeListener('drop', this.drop);
  }
}


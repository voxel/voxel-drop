# voxel-drop

Drag and drop various types of files to load them into your game (voxel.js plugin)

Uses the [W3C File API](http://www.w3.org/TR/FileAPI/) to read file data dropped by the user from
their desktop to the browser. Currently recognizes:

* .zip or .jar: loads textures using [artpacks](https://github.com/deathcap/artpacks) (hold shift to clear)
* .js: loads JavaScript and/or plugins using [voxel-plugins](https://github.com/deathcap/voxel-plugins)
* .coffee: same as .js but first compiles [CoffeeScript](http://coffeescript.org/)
* .dat: loads MC player.dat inventory files using [playerdat](https://github.com/deathcap/playerdat) into [voxel-carry](https://github.com/deathcap/voxel-carry) (hold shift to append)

## License

MIT


# CobaltDB
Pure lua database supporting multiple clients based on json & luasocket

code is based on [prestonelam2003/CobaltEssentials](https://github.com/prestonelam2003/CobaltEssentials/)

## Setup:

This is a BeamMP server plugin, and as such it runs inside a BeamMP server. Extract the contents of this folder into `Resources/Server/CobaltDB`. Players shouldn't join this server, so I recommend setting the `MaxPlayers` value to `0`, and using a placeholder text for the `AuthKey`. **Don't forget to change the server's port!*

### To use this with CobaltEssentials:
Put the `client/RemoteDBconnector.lua` file in `CobaltEssentials/lua/`.

Put the `client/CobaltDB.lua` file in `CobaltEssentials/`, this is just a dummy file preventing a luasocket related crash.

in `CobaltEssentialsLoader.lua` change the line
```lua
CobaltDB = require("CobaltDBconnector")
```

to

```lua
--CobaltDB = require("CobaltDBconnector")
CobaltDB = require("RemoteDBconnector")
```

Run this server and your DB client once, this will generate `dbConfig.json` files inside both. Fill these out as you'd like, the default values should work.

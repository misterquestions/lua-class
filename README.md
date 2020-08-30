# Lua class
A library to add support for OOP on Lua with a really nice and elegant style

## How to use?
Just download the include.lua file and include it to your project, it will work in any project that uses lua. This has been tested on "Multi Theft Auto" with Lua 5.1.

* Note: For Lua 5.3 you'll have to change `unpack` function for `table.unpack`.

## Create your first class
Its pretty easy, as said it adds support to create classes using an elegant syntax

```Lua
class 'HelloWorld' {
  constructor = function(self, arg1, arg2, ...)
  
  end,
  
  destructor = function(self)
  
  end,
  
  greet = function(self)
    print('Hello world!');
  end,
}
```

## Inheritance
The library supports class single inheritance and multiple inheritance preserving a nice style.

### Single class inheritance
```Lua
class 'Gamemode' {
  constructor = function(self)
    self.players = {};
    self.map = false;
    self.state = GamemodeState.NotRunning;
  end,
  
  destructor = function(self)
    -- Do something with players I guess
  end,
  
  unloadMapForPlayer = function(self, player)
    player:triggerClientEvent('unloadMap');
  end,
}

class 'RaceGamemode (Gamemode) {
  constructor = function(self)
    self.vehicles = {};
    self.checkpoints = {};
  end,
  
  destructor = function(self)
    self:unloadPlayers();
  end,
  
  unloadPlayers = function(self)
    for _, player in pairs(self.players) do
      self:unloadMapForPlayer(player);
      self:destroyPlayerVehicle(player);
    end
  end,
  
  destroyPlayerVehicle = function(self, player)
    self.vehicles[player]:destroy();
    self.vehicles[player] = nil;
  end,
}
```

### Multiple class inheritance
```Lua
include 'gamemodes.lua'

class 'TeamGamemode' {
  constructor = function(self)
    self.teamA = Team(...)
    self.teamB = Team(...)
  end,
  
  assignPlayerTeam = function(self, player)
    local randomTeam = math.random(0, 1)
    if (randomTeam == 0) then
      player:setTeam(self.teamA);
    else
      player:setTeam(self.teamB);
    end
  end,
}

class 'Deathmatch' (Gamemode, TeamGamemode) {
  onPlayerJoin = function(self, player)
    self:assignPlayerTeam(player);
    self:checkGameState();
  end,
  
  checkGameState = function(self)
    if (self:getAlivePlayersCount() < 1) then
      self:startNextRound();
    end
  end,
}
```

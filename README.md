# TetraCore

Dylan Cooper CIS 4900 Project

Use this to play Connect 4 against against people with similar clients
over an IRC connection.

## To Get Dependencies

```
mix deps.get
```

## To Build Command Line Application

```
mix escript.build
```

## To Run Command Line Application

```
./tetra-core
```

Command line arguments:

Configuring the IRC server:

```
 --host=<host> IRC Server - defaults to chat.freenode.net
 --user=<username> IRC Username - defaults to tetrabot
 --nick=<nickname> IRC Nickname - defaults to tetrabot
 --pass=<password> IRC Password - defaults to tetrabotpass
 --name=<name> IRC Name - defaults to Tetra Robot
```

To play against the AI:

```
 --bot
```


## Installation

In addition to a command line application, this program can be used as
a library in other Elixir applications, more documentation will be
available shortly.

  1. Add tetra_core to your list of dependencies in `mix.exs`:

        def deps do
          [{:tetra_core, git: "https://github.com/dylan-cooper/tetra_core"}]
        end

  2. Ensure tetra_core is started before your application:

        def application do
          [applications: [:tetra_core]]
        end

## Primary uses as a library

Start an IRC Connection:

```
TetraIRC.ConnectionHandlerSupervisor.start_irc_connection(%{host: host, port: port, user: user, name: name, pass: pass, nick: nick, channels: channels})
```

Start an IRC Player:

```
TetraIRC.GameHandlerSupervisor.start_game_handler(client, channel, opponent, game_key)
TetraIRC.set_game(irc_handler, game)
```

Start a Game:

```
TetraCore.GameSupervisor.start_game(player1, player2)
```

Start an AI Player:

```
TetraCore.TetraBot.start_link
TetraCore.TetraBot.set_game(bot, game)
```



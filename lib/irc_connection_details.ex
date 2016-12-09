defmodule IRCConnectionDetails do
  defstruct host: "chat.freenode.net",
            port: 6667,
            pass: "tetrabotpass",
            nick: "tetrabot",
            user: "tetrabot",
            name: "Tetra Robot",
            channels: ["#tetra-testing"]
end

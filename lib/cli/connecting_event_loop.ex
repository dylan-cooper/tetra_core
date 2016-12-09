defmodule CLI.ConnectingEventLoop do
  def start(_, connection_details \\ %IRCConnectionDetails{}) do
    TetraIRC.ConnectionHandlerSupervisor.start_irc_connection(connection_details, self)
    IO.write "Connecting to " <> connection_details.host <> ": "
    result = wait_for_connection_complete
    IO.puts "Successfully connected to " <> connection_details.host
    result
  end

  def wait_for_connection_complete(n \\ 0) do
    chars = "|/-\\"
    receive do
      :connection_complete -> 
        IO.write "\b\n"
        :ok
    after
      200 ->
        IO.write "\b" <> String.at(chars, n) 
        rem(n + 1, 4) |> wait_for_connection_complete
    end
  end
end

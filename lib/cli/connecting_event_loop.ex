defmodule CLI.ConnectingEventLoop do

  def start({%{bot: true}, _}) do
    :bot
  end

  def start(args) do
    import TetraIRC.ConnectionHandlerSupervisor

    connection_details = args
      |> init_connection_details

    start_irc_connection(connection_details, self)
    IO.write "Connecting to " <> connection_details.host <> ": "
    result = wait_for_connection_complete
    IO.puts "Successfully connected to " <> connection_details.host
    result
  end

  def init_connection_details({parsed, rest}) do
    port = Map.fetch(parsed, :port)
      |> case do
        {:ok, p} -> p
        :error -> "6667"
      end
      |> Integer.parse
      |> case do
        {n, ""} -> n
        _ -> 6667
      end

    channels = case rest do
      [] -> ["#tetra-testing2"]
      l -> l
    end

    defaults = %{
      host: "chat.freenode.net",
      user: "tetrabot",
      nick: "tetrabot",
      name: "Tetra Robot",
      pass: "tetrabotpass",
    }

    defaults
      |> Map.merge(%{port: port, channels: channels})
      |> Map.merge(parsed)
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

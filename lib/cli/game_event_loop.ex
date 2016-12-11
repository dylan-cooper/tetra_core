defmodule CLI.GameEventLoop do

  defmodule State do
    defstruct game: nil
  end

  def start({:ok, {client, channel, nick, game_key}}) do
    #Use match to start a game and initialize state

    IO.puts "About to call start_game_handler"
    {:ok, irc_handler} = TetraIRC.GameHandlerSupervisor.start_game_handler(client, channel, nick, game_key)

    IO.ANSI.green()
    IO.puts "About to call start_game"
    IO.ANSI.default_color()
    {:ok, game} = TetraCore.GameSupervisor.start_game(irc_handler, self)

    TetraIRC.GameHandler.set_game(irc_handler, game)

    state = %State{game: game}
    event_loop(state)
  end

  def event_loop(state) do
    input = IO.gets "Tetra > "
    input 
      |> String.strip(?\n)
      |> String.split(" ", parts: 2, trim: true)
      |> respond_to_input(state)
  end

  def respond_to_input(["quit"], _state) do
    :ok
  end

  def respond_to_input(["drop", column], state) do
    IO.puts "Should drop piece in " <> column
    {column_n, ""}  = Integer.parse(column)
    reply = TetraCore.TetraGame.drop_piece(state.game, column_n)

    case reply do
      :ok ->
        IO.puts "Told this was okay in event loop"
      :win ->
        IO.puts "Ooh, you won!"
      {:error, _message} ->
        IO.puts "Told there was an error in event loop"
    end
    event_loop(state)
  end

  def respond_to_input(["display"], state) do
    IO.puts "Should display the board"
    state.game
      |> TetraCore.TetraGame.get_grid    
      |> display_grid

    event_loop(state)
  end

  def respond_to_input(["chat", message], state) do
    IO.puts "Would send chat message " <> message
    event_loop(state)
  end

  def respond_to_input(["help"], state) do
    IO.puts "Should display help menu"
    event_loop(state)
  end

  def respond_to_input(_, state) do
    IO.puts "Undefined command.  To review commands, use the help command"
    event_loop(state)
  end

  defp display_grid(grid) do
    grid
      |> Map.to_list
      |> Enum.sort(fn ({{x1, y1}, _}, {{x2, y2}, _}) ->
          if (y2 == y1), do: x2 > x1, else: y2 < y1 end)
      |> Enum.each(
        fn
          {{6, _}, %{player: player}} ->
            write_color(player)
            IO.write("\e[49m\n")
          {_, %{player: player}} ->
            write_color(player)
        end)
    IO.write('\n')
  end

  defp write_color(:player1) do
    IO.write("\e[41m  ")
  end

  defp write_color(:player2) do
    IO.write("\e[44m  ")
  end

  defp write_color(nil) do
    IO.write("\e[47m  ")
  end
  
end

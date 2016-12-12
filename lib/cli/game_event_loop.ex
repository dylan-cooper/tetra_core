defmodule CLI.GameEventLoop do

  defmodule State do
    defstruct game: nil
  end

  def start(:bot) do
    {:ok, bot} = TetraCore.TetraBot.start_link()
    {:ok, game} = TetraCore.GameSupervisor.start_game(self, bot)
    TetraCore.TetraBot.set_game(bot, game)
    state = %State{game: game}
    event_loop(state)
  end

  def start({:ok, {client, channel, nick, game_key, true}}) do
    {:ok, irc_handler} = TetraIRC.GameHandlerSupervisor.start_game_handler(client, channel, nick, game_key)
    {:ok, game} = TetraCore.GameSupervisor.start_game(self, irc_handler)
    TetraIRC.GameHandler.set_game(irc_handler, game)
    state = %State{game: game}
    event_loop(state)
  end

  def start({:ok, {client, channel, nick, game_key, false}}) do
    {:ok, irc_handler} = TetraIRC.GameHandlerSupervisor.start_game_handler(client, channel, nick, game_key)
    {:ok, game} = TetraCore.GameSupervisor.start_game(irc_handler, self)
    TetraIRC.GameHandler.set_game(irc_handler, game)
    state = %State{game: game}
    wait_for_next_turn(state)
  end

  def start(:quit), do: :quit

  def event_loop(state) do
    input = IO.gets "Tetra > "
    input 
      |> String.strip(?\n)
      |> String.split(" ", parts: 2, trim: true)
      |> respond_to_input(state)
  end

  def respond_to_input(["quit"], _state) do
    :quit
  end

  def respond_to_input(["drop", column], state) do
    case Integer.parse(column) do
      {column_n, ""} ->
        do_drop(column_n, state)
      _ ->
        IO.puts "That column isn't valid."
        event_loop(state)
    end
  end

  def respond_to_input(["display"], state) do
    display_board(state)

    event_loop(state)
  end

  def respond_to_input(["chat", message], state) do
    TetraCore.Game.send_chat(state.game, message)
    event_loop(state)
  end

  def respond_to_input(["help"], state) do
    IO.puts "chat <message> - Send a message to the opponent"
    IO.puts "drop <column> - Drop a piece in a given column (columns go from 0 to 6)"
    IO.puts "display - Display the current board"
    IO.puts "quit - Quit the program"
    event_loop(state)
  end

  def respond_to_input(_, state) do
    IO.puts "Undefined command.  To review commands, use the help command"
    event_loop(state)
  end

  def do_drop(column, state) do
    reply = TetraCore.Game.drop_piece(state.game, column)

    case reply do
      :ok ->
        display_board(state)
        wait_for_next_turn(state)
      :tie ->
        display_board(state)
        IO.puts "The game ended in a tie!"
        :ok
      :win ->
        display_board(state)
        IO.puts "Congratulations, you won!"
        :ok
      :not_your_turn ->
        IO.puts "Don't know how this happened, but it's not your turn!"
        wait_for_next_turn(state)
      {:error, _message} ->
        IO.puts "That column isn't valid."
        event_loop(state)
    end
  end

  defp wait_for_next_turn(state) do
    CLI.Helpers.wait_for(
      "Waiting for the opponent to make a move",
      fn
        {:opponent_moved, _} -> true
        {:opponent_won, _} -> true
        {:opponent_tied, _} -> true
        {:opponent_resigned, _} -> true
        _ -> false
      end,
      fn
        {:opponent_moved, column} ->
          IO.write "\n"
          IO.puts "Your opponent dropped a tile in column " <> Integer.to_string(column)
          display_board(state)
          event_loop(state)
        {:opponent_tied, column} ->
          IO.write "\n"
          IO.puts "Your opponent dropped a tile in column " <> Integer.to_string(column)
          display_board(state)
          IO.puts "The game is over, it was a tie!"
          :ok
        {:opponent_won, column} ->
          IO.write "\n"
          IO.puts "Your opponent dropped a tile in column " <> Integer.to_string(column)
          display_board(state)
          IO.puts "Your opponent has won the game!"
          :ok
        {:opponent_sent_chat, message} ->
          IO.puts "\nMessage from opponent: " <> message
          IO.write "Waiting for the opponent to make a move: |"
        {:opponent_resigned, message} ->
          IO.puts "\nYour opponent has resigned: " <> message
          :ok
        msg ->
          IO.inspect :stderr, msg
      end
    )
  end

  defp display_board(state) do
    state.game
      |> TetraCore.Game.get_grid    
      |> display_grid
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

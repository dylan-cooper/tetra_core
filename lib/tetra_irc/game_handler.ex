defmodule TetraIRC.GameHandler do
  use GenServer

  defmodule State do
    defstruct channel: nil,
              opponent_nick: nil,
              game_key: nil,
              client: nil,
              game_pid: nil
  end

  def start_link(client, channel, opponent, game_key) do
    state = %State{
      client: client,
      channel: channel,
      opponent_nick: opponent,
      game_key: game_key
    }

    GenServer.start_link(__MODULE__, [state])
  end

  def set_game(game_handler, game_pid) do
    GenServer.call(game_handler, {:set_game, game_pid})
  end

  def init([state]) do
    ExIrc.Client.add_handler state.client, self
    {:ok, state}
  end

  def handle_call({:set_game, player}, _from, state) do
    {:reply, :ok, %{state | game_pid: player}}
  end

  def handle_info({:received, msg, %{nick: sender}, channel}, state = %{channel: channel, opponent_nick: sender}) do
    IO.puts "Wooow: " <> msg
    String.split(msg, ":") |> respond_to_message(state)
    {:noreply, state}
  end

  def handle_info({:opponent_moved, column}, state) do
    IO.puts "Sending the message over IRC"
    send_irc_message("PLAY:" <> state.game_key <> ":" <> Integer.to_string(column), state)
    {:noreply, state}
  end

  def handle_info({:opponent_won, column}, state) do
    send_irc_message("WIN:" <> state.game_key <> ":" <> Integer.to_string(column), state)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def respond_to_message(["PLAY", game_key, arg], state = %{game_key: game_key}) do
    case Integer.parse(arg) do
      {column, ""} when column >= 0 and column <= 6 ->
        IO.puts "Opponent sent valid PLAY"
        TetraCore.Player.drop_piece(state.game_pid, column)
          |> respond_to_drop(:play, state)
      _ ->
        send_irc_message("CHEAT:INVALID_COLUMN", state)
    end
  end

  def respond_to_message(["WIN", game_key, arg], state = %{game_key: game_key}) do
    case Integer.parse(arg) do
      {column, ""} when column >= 0 and column <= 6 ->
        IO.puts "Opponent sent valid PLAY"
        TetraCore.Player.drop_piece(state.game_pid, column)
          |> respond_to_drop(:win, state)
      _ ->
        send_irc_message("CHEAT:" <> state.game_key <> ":INVALID_COLUMN", state)
    end
  end

  def respond_to_message(["WIN_AGREE", game_key], _state = %{game_key: game_key}) do
    IO.puts "Opponent agreed that you won"
  end

  def respond_to_message(["CHEAT", game_key, "WRONG_TURN"], _state = %{game_key: game_key}) do
    IO.puts "Opponent has accused you of moving when it wasn't your turn!"
  end

  def respond_to_message(["CHEAT", game_key, "INVALID_COLUMN"], _state = %{game_key: game_key}) do
    IO.puts "Opponent has accused you of choosing an invalid column!"
  end

  def respond_to_message(["CHEAT", game_key, "WIN_DISAGREE"], _state = %{game_key: game_key}) do
    IO.puts "Opponent has accused you of claiming that you've won when you haven't!"
  end

  def respond_to_message(["CHAT", game_key, msg], _state = %{game_key: game_key}) do
    IO.puts "Opponent has sent you a chat message: " <> msg
  end

  def respond_to_message(["RESIGN", game_key, msg], state = %{game_key: game_key}) do
    opponent_resigned(msg, state)
  end

  def respond_to_message(["QUIT", game_key, msg], state = %{game_key: game_key}) do
    opponent_resigned(msg, state)
  end

  def respond_to_message(l, state) do
    IO.puts "Didn't recognize this one"
    IO.inspect l
    IO.inspect state
    :ok
  end

  def respond_to_drop(:ok, :play, _) do
    :ok
  end

  def respond_to_drop(:win, :play, state) do
    send_irc_message("RESIGN:" <> state.game_key <> ":Hmm, looks like you actually won.", state)
  end

  def respond_to_drop(:ok, :win, state) do
    send_irc_message("CHEAT:" <> state.game_key <> ":WIN_DISAGREE", state)
  end

  def respond_to_drop(:win, :win, state) do
    send_irc_message("WIN_AGREE:" <> state.game_key, state)
  end

  def respond_to_drop({:error, _}, _, state) do
    send_irc_message("CHEAT:" <> state.game_key <> ":INVALID_COLUMN", state)
  end

  def opponent_resigned(msg \\ "", _state) do
    IO.puts "Opponent has decided to resign: " <> msg 
  end

  defp send_irc_message(msg, state) do
    ExIrc.Client.msg(state.client, :privmsg, state.channel, msg)
  end
end

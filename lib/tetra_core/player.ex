defmodule TetraCore.Player do
  use GenServer

  defmodule State do
    defstruct id: nil,
              subscriber: nil,
              game: nil
  end

  def start_link(id, subscriber, game) do
    GenServer.start_link(__MODULE__, [id, subscriber, game])
  end

  def drop_piece(player, column) do
    IO.inspect {player, column}
    GenServer.call(player, {:drop_piece, column})
  end

  def init([id, subscriber, game]) do
    IO.puts "Starting a Player"
    state = %State{id: id, subscriber: subscriber, game: game}
    IO.inspect state

    {:ok, state}
  end

  def handle_call({:drop_piece, column}, _from, state) do
    IO.puts "In player, was asked to drop piece in column: " <> Integer.to_string(column)
    board = get_board(state)

    case TetraCore.Board.drop(board, state.id, column) do
      :ok ->
        opponent = get_opponent(state)
        GenServer.cast(opponent, {:opponent_moved, column})
        {:reply, :ok, state}
      :win ->
        opponent = get_opponent(state)
        GenServer.cast(opponent, {:opponent_won, column})
        {:reply, :win, state}
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_cast({:opponent_moved, column}, state) do
    IO.puts "Player was informed that their opponent moved"
    Kernel.send(state.subscriber, {:opponent_moved, column})
    {:noreply, state}
  end

  def handle_cast({:opponent_won, column}, state) do
    IO.puts "Player was informed that their opponent won"
    #send info to a subscriber
    Kernel.send(state.subscriber, {:opponent_won, column})
    {:noreply, state}
  end

  #INTERNAL API (SHOULD PROBABLY BE MOVED OUT OF HERE)

  defp get_board(state) do
    TetraCore.Game.get_worker(state.game, :board)
  end

  defp get_opponent(state) do
    case state.id do
      :player1 -> TetraCore.Game.get_worker(state.game, :player2)
      :player2 -> TetraCore.Game.get_worker(state.game, :player1)
    end
  end
end

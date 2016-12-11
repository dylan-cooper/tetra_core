defmodule TetraCore.TetraGame do
  use GenServer

  defmodule State do
    defstruct player1: nil, #subscriber pid
              player2: nil, #subscriber pid
              grid: nil,
              prev: nil,
              winner: nil
  end

  def start_link(player1, player2) do
    GenServer.start_link(__MODULE__, [player1, player2])
  end

  def drop_piece(game, column) do
    GenServer.call(game, {:drop_piece, column})
  end

  def get_grid(game) do
    GenServer.call(game, :get_grid)
  end

  def init([player1, player2]) do
    init_grid =
      for x <- 0 .. 6,
          y <- 0 .. 5,
          into: %{},
          do: {{x,y}, %{player: nil}}

    init_state = %State{
      player1: player1,
      player2: player2,
      grid: init_grid,
      prev: nil,
      winner: nil
    }
    
    {:ok, init_state}
  end

  def handle_call({:drop_piece, column}, {from_pid, _}, state) do
    IO.puts "In game, was asked to drop piece for player"
    IO.inspect state
    IO.inspect from_pid

    get_player(from_pid, state) |> do_drop_piece(column, state)
  end

  def handle_call(:get_grid, _from, state) do
    {:reply, state.grid, state}
  end

  #Internal API

  def get_player(pid, %{player1: pid}), do: :player1
  def get_player(pid, %{player2: pid}), do: :player2

  def get_opponent_pid(:player1, state), do: state.player2
  def get_opponent_pid(:player2, state), do: state.player1

  def do_drop_piece(player, column, state) do
    try do
      new_state = state
        |> drop_piece(player, column, 0)
        |> check_winner(player)

      opponent = get_opponent_pid(player, new_state)

      case new_state.winner do
        nil -> 
          Kernel.send(opponent, {:opponent_moved, column})
          {:reply, :ok, new_state}
        _winner ->
          Kernel.send(opponent, {:opponent_won, column})
          {:reply, :win, new_state}
      end 
    rescue
      e in RuntimeError ->
        {:reply, {:error, e.message}, state}
    end
  end

  defp drop_piece(state = %{grid: grid}, player, column, row) do
    square = Map.get(grid, {column, row})

    cond do
      is_nil(square) ->
        raise "Invalid Move"
      square == %{player: nil} ->
        %{state | grid: Map.put(grid, {column, row}, %{player: player}), prev: {column, row}} 
      true ->
        drop_piece(state, player, column, row + 1)
    end
  end
  
  defp check_winner(state, player) do
    if did_win(state) do
      %{state | winner: player}
    else
      state
    end
  end

  defp did_win(%{prev: nil}) do
    false
  end

  defp did_win(state) do
    player = Map.get(state.grid, state.prev)

    check(state, player, 1, fn ({x, y}, delta) -> {x - delta, y + delta} end)
    || check(state, player, 1, fn ({x, y}, delta) -> {x - delta, y} end)
    || check(state, player, 1, fn ({x, y}, delta) -> {x - delta, y - delta} end)
    || check(state, player, 1, fn ({x, y}, delta) -> {x, y - delta} end)
    || check(state, player, 1, fn ({x, y}, delta) -> {x + delta, y - delta} end)
    || check(state, player, 1, fn ({x, y}, delta) -> {x + delta, y} end)
    || check(state, player, 1, fn ({x, y}, delta) -> {x + delta, y + delta} end)
  end

  defp check(state = %{grid: grid, prev: {x, y}}, player, position, transform) when position < 3 do
    coord = transform.({x, y}, position)

    if Map.get(grid, coord) == player do
      check(state, player, position + 1, transform)
    else
      false
    end
  end

  defp check(%{grid: grid, prev: {x, y}}, player, 3, transform) do
    coord_forwards = transform.({x, y}, 3)
    coord_backwards = transform.({x, y}, -1)

    Map.get(grid, coord_forwards) == player || Map.get(grid, coord_backwards) == player
  end
end

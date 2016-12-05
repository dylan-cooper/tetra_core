defmodule TetraCore.Board do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def drop(pid, player, column) do
    GenServer.call(pid, {:drop, player, column})
  end

  def handle_call({:drop, player, column}, _from, state) do
    try do
      new_state = state
      |> drop_piece(player, column, 0)
      |> check_winner(player)

      {:reply, {:ok, new_state}, new_state}
    rescue
      e in RuntimeError ->
        {:reply, {:error, e.message}, state}
    end
  end

  def init(:ok) do
    init_grid =
      for x <- 0 .. 6,
          y <- 0 .. 5,
          into: %{},
          do: {{x,y}, %{player: nil}}

    init_state = %{grid: init_grid, prev: nil, winner: nil}
    
    {:ok, init_state}
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

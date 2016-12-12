defmodule TetraCore.Game do
  use GenServer

  defmodule State do
    defstruct player1: nil, #subscriber pid
              player2: nil, #subscriber pid
              grid: nil,
              prev: nil,
              turn: nil,
              full: false,
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

  def get_valid_columns(game) do
    GenServer.call(game, :get_valid_columns)
  end

  def send_chat(game, message) do
    GenServer.call(game, {:send_chat, message})
  end

  def resign(game, message) do
    GenServer.call(game, {:resign, message})
  end

  def find_best_move(game) do
    GenServer.call(game, :find_best_move)
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
      turn: :player1,
      winner: nil
    }
    
    {:ok, init_state}
  end

  def handle_call({:drop_piece, column}, {from_pid, _}, state) do
    get_player(from_pid, state) 
      |> do_drop_piece(column, state)
  end

  def handle_call(:get_grid, _from, state) do
    {:reply, state.grid, state}
  end

  def handle_call(:get_valid_columns, _from, state) do
    result = state.grid
      |> Enum.filter(fn {{_x, y}, %{player: p}} -> y == 5 and p == nil end)
      |> Enum.map(fn {{x, _y}, _p} -> x end)

    {:reply, result, state}
  end

  def handle_call({:send_chat, message}, {from_pid, _}, state) do
    from_pid
      |> get_player(state)
      |> get_opponent_pid(state)
      |> Kernel.send({:opponent_sent_chat, message})
    
    {:reply, :ok, state}
  end

  def handle_call({:resign, message}, {from_pid, _}, state) do
    from_pid
      |> get_player(state)
      |> get_opponent_pid(state)
      |> Kernel.send({:opponent_resigned, message})

    {:reply, :ok, state}
  end

  def handle_call(:find_best_move, _from, state) do
    column = do_find_best_move(state)
    {:reply, column, state}
  end

  #Internal API

  def get_player(pid, %{player1: pid}), do: :player1
  def get_player(pid, %{player2: pid}), do: :player2

  def get_opponent_pid(:player1, state), do: state.player2
  def get_opponent_pid(:player2, state), do: state.player1

  def change_turn(state = %{turn: :player1}), do: %{state | turn: :player2}
  def change_turn(state = %{turn: :player2}), do: %{state | turn: :player1}

  def check_full(state = %{grid: grid}) do
    result = grid
      |> Enum.filter(fn {{_x, _y}, %{player: p}} -> p != nil end)
      |> Enum.empty?

    %{state | full: result}
  end

  #kind of gross function, should fix later
  def do_drop_piece(player, column, state = %{turn: player}) do
      case perform_drop_piece(player, column, state) do
        {:error, msg} ->
          {:reply, {:error, msg}, state}
        new_state ->
          opponent_pid = get_opponent_pid(player, new_state)
          
          case {new_state.winner, new_state.full} do
            {nil, false} -> 
              Kernel.send(opponent_pid, {:opponent_moved, column})
              {:reply, :ok, new_state}
            {nil, true} ->
              Kernel.send(opponent_pid, {:opponent_tied, column})
              {:reply, :tie, new_state}
            {_winner, _} ->
              Kernel.send(opponent_pid, {:opponent_won, column})
              {:reply, :win, new_state}
          end 
      end
  end

  def do_drop_piece(_player, _column, state) do
    {:reply, :not_your_turn, state}
  end

  def try_drop_piece(player, column, state) do
    state
      |> insert_piece(player, column, 0)
      |> check_winner(player)
      |> change_turn
      |> check_full
  end

  def perform_drop_piece(player, column, state) do
    try do
      try_drop_piece(player, column, state)
    rescue
      e in RuntimeError ->
        {:error, e.message}
    end
  end

  defp insert_piece(state = %{grid: grid}, player, column, row) do
    square = Map.get(grid, {column, row})

    cond do
      is_nil(square) ->
        raise "Invalid Move"
      square == %{player: nil} ->
        %{state | grid: Map.put(grid, {column, row}, %{player: player}), prev: {column, row}} 
      true ->
        insert_piece(state, player, column, row + 1)
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

  defp do_find_best_move(state) do
    {:found, column} = find_winning_move(:not_found, state)
      |> find_stopping_move(state)
      |> find_center_move(state)
      |> find_edge_move(state)
      |> find_corner_move(state)

    column
  end

  defp find_winning_move(:not_found, state) do
    list = Enum.map(0..6, fn n -> perform_drop_piece(state.turn, n, state) end)
    l = for %State{} = s<- list, do: s
    l
      |> Enum.filter(fn s -> did_win(s) end)
      |> Enum.map(fn %{prev: {x, _y}} -> x end)
      |> case do
        [] -> :not_found
        columns -> {:found, Enum.random(columns)}
      end
  end

  defp find_stopping_move(:not_found, state) do
    player = case state.turn do 
      :player1 -> :player2
      :player2 -> :player1
    end

    list = Enum.map(0..6, fn n -> perform_drop_piece(player, n, state) end)

    l = for %State{} = s <- list, do: s

    l
      |> Enum.filter(fn s -> did_win(s) end)
      |> Enum.map(fn %{prev: {x, _y}} -> x end)
      |> case do
        [] -> :not_found
        columns -> {:found, Enum.random(columns)}
      end
  end
  
  defp find_stopping_move(val, _state), do: val

  defp find_center_move(:not_found, state) do
    list = Enum.map(1..5, fn n -> perform_drop_piece(state.turn, n, state) end)

    l = for %State{} = s <- list, do: s
    l
      |> Enum.filter(fn %{prev: {_x, y}} -> y != 5 end)
      |> Enum.map(fn %{prev: {x, _y}} -> x end)
      |> case do
        [] -> :not_found
        columns -> {:found, Enum.random(columns)}
      end
  end

  defp find_center_move(val, _state), do: val

  defp find_edge_move(:not_found, state) do
    list = Enum.map(0..6, fn n -> perform_drop_piece(state.turn, n, state) end)

    l = for %State{} = s <- list, do: s
    l
      |> Enum.filter(fn %{prev: {x, y}} -> {x, y} != {0, 0} and {x, y} != {0, 5} and {x, y} != {6, 0} and {x, y} != {6, 5} end)
      |> Enum.map(fn %{prev: {x, _y}} -> x end)
      |> case do
        [] -> :not_found
        columns -> {:found, Enum.random(columns)}
      end
  end

  defp find_edge_move(val, _state), do: val

  defp find_corner_move(:not_found, state) do
    list = Enum.map(0..6, fn n -> perform_drop_piece(state.turn, n, state) end)

    l = for %State{} = s <- list, do: s
    l
      |> Enum.map(fn %{prev: {x, _y}} -> x end)
      |> case do
        [] -> :not_found
        columns -> {:found, Enum.random(columns)}
      end
  end

  defp find_corner_move(val, _state), do: val
end

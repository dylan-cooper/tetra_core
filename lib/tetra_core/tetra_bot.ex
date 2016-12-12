defmodule TetraCore.TetraBot do
  use GenServer
  import TetraCore.Game

  defmodule State do
    defstruct game_pid: nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, [%State{}])
  end

  def set_game(bot, game_pid) do
    GenServer.call(bot, {:set_game, game_pid})
  end

  def init([state]) do
    {:ok, state}
  end
  
  def handle_call({:set_game, game}, _from, state) do
    {:reply, :ok, %{state | game_pid: game}}
  end

  def handle_info({:opponent_moved, _column}, state) do
    random_column = get_valid_columns(state.game_pid)
      |> Enum.random

    drop_piece(state.game_pid, random_column)
      |> respond_to_drop(state)
    {:noreply, state}
  end

  def handle_info({:opponent_tied, _column}, state) do
    send_chat(state.game_pid, "Good game!  You almost had me!")
    {:noreply, state}
  end

  def handle_info({:opponent_won, _column}, state) do
    send_chat(state.game_pid, "Wow, those were some moves!")
    {:noreply, state}
  end

  def handle_info({:opponent_sent_chat, _message}, state) do
    {:noreply, state}
  end

  def handle_info({:opponent_resigned, _message}, state) do
    end_game(state)
    {:noreply, state}
  end

  def respond_to_drop(:ok, _state), do: :ok

  def respond_to_drop(:tie, state) do 
    send_chat(state.game_pid, "Good game!  I almost had you!")
  end

  def respond_to_drop(:win, state) do
    send_chat(state.game_pid, "Woohoo!  Better luck next time!")
  end

  def respond_to_drop({:error, _msg}, state) do
    resign(state.game_pid, "Something must have gone wrong, I would never make an invalid move!")
    end_game(state)
  end

  def end_game(_state) do
    GenServer.stop(self)
  end
end

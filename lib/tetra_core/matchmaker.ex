defmodule TetraCore.Matchmaker do
  use GenServer

  defmodule State do
    defstruct open_challenges: [],
              current_games: []
  end

  def start_link(name, state \\%State{}) do
    GenServer.start_link(__MODULE__, [state], name: name)
  end

  def init([state]) do
    {:ok, state}
  end

  def handle_cast({:found_acceptor, {challenge_id, acceptor, channel}}, state) do
    IO.puts "Got a message in matchmaker to tell me that " <> acceptor <> " accepted " <> challenge_id
    {:noreply, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  
end

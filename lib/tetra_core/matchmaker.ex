defmodule TetraCore.Matchmaker do
  use GenServer

  defmodule State do
    defstruct open_challenges: []
  end

  def start_link(name, state \\%State{}) do
    GenServer.start_link(__MODULE__, [state], name: name)
  end

  def init([state]) do
    {:ok, state}
  end

  def handle_call(:get_all_challenges, _from, state) do
    {:reply, state.open_challenges, state}
  end

  def handle_call(:get_and_close_any_challenge, _from, state = %{open_challenges: [head | tail]}) do
    {:reply, head, %{state | open_challenges: tail}}
  end

  def handle_call(:get_and_close_any_challenge, _from, state = %{open_challenges: []}) do
    {:reply, :challenge_not_found, state}
  end

  def handle_cast({:open_challenge, {id, name, type}}, state) do
    open_challenges = state.open_challenges ++ [{id, name, type}]
    {:noreply, %{state | open_challenges: open_challenges}}
  end

  def handle_call({:get_and_close_challenge, {id}}, state) do
    challenge = state.open_challenges |>  
      Enum.find(fn {a, _, _} -> a == id end)

    case challenge do
      {id, name, type} ->
        open_challenges = state.open_challenges |>
          Enum.filter(fn a -> a != {id, name, type} end)
        {:reply, challenge, %{state | open_challenges: open_challenges}}
      nil ->
        {:reply, :challenge_not_found, state}
    end
  end
  
#
#  def handle_cast({:found_acceptor, {challenge_id, acceptor, channel}}, state) do
#    IO.puts "Got a message in matchmaker to tell me that " <> acceptor <> " accepted " <> challenge_id
#    {:noreply, state}
#  end
  
end

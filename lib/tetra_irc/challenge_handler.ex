defmodule TetraIRC.ChallengeHandler do
  use GenServer

  defmodule State do
    defstruct open_challenges: [], #challenges opened by other people on IRC
              my_open_challenges: [], # challenges opened by this tetrabot on IRC
              clients: []
  end

  def start_link(state \\ %State{}) do
    GenServer.start_link(__MODULE__, [state], name: :challenge_handler)
  end

  def init([state]) do
    {:ok, state}
  end

  ##PUBLIC API

  def get_state do
    GenServer.call(:challenge_handler, :get_state)
  end

  def add_client(client) do
    GenServer.call(:challenge_handler, {:add_client, client})
  end

  def get_clients do
    GenServer.call(:challenge_handler, :get_clients)
  end

  def get_all_open_challenges do
    GenServer.call(:challenge_handler, :all_open_challenges)
  end

  def accept_challenge(challenge_id) do
    GenServer.call(:challenge_handler, {:accept_challenge, {challenge_id}})
  end

  def open_challenge_async(client, channel, challenge_id, subscriber) do
    GenServer.cast(:challenge_handler, {:open_challenge, {client, channel, challenge_id, subscriber}})
  end

  def cancel_challenge_async(client, channel, challenge_id) do
    GenServer.cast(:challenge_handler, {:cancel_challenge, {client, channel, challenge_id}})
  end

  ##HANDLING CALLS/CASTS

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_clients, _from, state) do
    {:reply, state.clients, state}
  end

  def handle_call({:add_client, client}, _from, state) do
    ExIrc.Client.add_verbose_handler client, self
    clients = state.clients ++ [client]
    {:reply, :ok, %{state | clients: clients}}
  end 

  def handle_call(:all_open_challenges, _from, state) do
    result = state.open_challenges
    {:reply, result, state}
  end

  #send an ACCEPT_CHALLENGE to the IRC chat
  def handle_call({:accept_challenge, {challenge_id}}, _from, state) do
    msg = "ACCEPT_CHALLENGE:" <> challenge_id
    challenge = state.open_challenges |> Enum.find(fn {_, _, id, _} -> id == challenge_id end)

    case challenge do
      {client, channel, challenge_id, nick} ->
        ExIrc.Client.msg(client, :privmsg, channel, msg)

        oc = state.open_challenges
          |> Enum.filter(fn {a, b, c, _} -> {a, b, c} != {client, channel, challenge_id} end)

        {:reply, {:ok, {client, channel, nick}}, %{state | open_challenges: oc}}
      nil ->
        {:reply, {:challenge_id_not_found, {challenge_id}}, state}
    end
  end

  #send an OPEN_CHALLENGE to the IRC chat
  def handle_cast({:open_challenge, challenge = {client, channel, challenge_id, _pid}}, state) do
    msg = "OPEN_CHALLENGE:V1:" <> challenge_id
    ExIrc.Client.msg(client, :privmsg, channel, msg)
    my_open_challenges = state.my_open_challenges ++ [challenge]
    {:noreply, %{state | my_open_challenges: my_open_challenges}}
  end

  #send a CANCEL_CHALLENGE to the IRC chat
  def handle_cast({:cancel_challenge, {client, challenge_id, channel}}, state) do
    msg = "CANCEL_CHALLENGE:" <> challenge_id
    ExIrc.Client.msg(client, :privmsg, channel, msg)
    my_open_challenges = state.my_open_challenges
      |> Enum.filter(fn {a, b, _} -> {a, b} != {channel, challenge_id} end)
    {:noreply, %{state | my_open_challenges: my_open_challenges}}
  end

  #receive an OPEN_CHALLENGE from the IRC chat
  def handle_info(%{msg: {:received, "OPEN_CHALLENGE:V1:" <> challenge_id, %{nick: challenger}, channel}, pid: client}, state) do
    #IO.puts challenger <> " sent V1 challenge in " <> channel <> " from:"
    #IO.inspect client
    open_challenges = state.open_challenges ++ [{client, channel, challenge_id, challenger}]
    {:noreply, %{state | open_challenges: open_challenges}}
  end

  #receive an ACCEPT_CHALLENGE from the IRC chat
  def handle_info(%{msg: {:received, "ACCEPT_CHALLENGE:" <> challenge_id, %{nick: acceptor}, channel}, pid: client}, state) do
    #IO.puts acceptor <> " accepted challenge with ID: " <> challenge_id <> " in " <> channel <> " from:"
    #IO.inspect client
    
    if (state.my_open_challenges |> Enum.any?(fn {a, b, c, _} -> {a, b, c} == {client, channel, challenge_id} end)) do
      #the challenge_id matches a challenge opened by tetrabot

      #send message to the pid associated
      {_, _, _, pid} = Enum.find(state.my_open_challenges, fn {a, b, c, _} -> {a, b, c} == {client, channel, challenge_id} end)
      #IO.inspect pid
      Kernel.send(pid, {:found_acceptor, {client, channel, challenge_id, acceptor}})

      #remove from my_open_challenges
      my_open_challenges = state.my_open_challenges
        |> Enum.filter(fn {a, b, c, _} -> {a, b, c} != {client, channel, challenge_id} end)

      {:noreply, %{state | my_open_challenges: my_open_challenges}}
    else
      #a challenge created by someone else is being accepted by someone else

      open_challenges = state.open_challenges
        |> Enum.filter(fn {a, b, c, _} -> {a, b, c} != {client, channel, challenge_id} end)

      {:noreply, %{state | open_challenges: open_challenges}}
    end
  end

  #received a cancel challenge from the IRC chat
  def handle_info(%{msg: {:received, "CANCEL_CHALLENGE:" <> challenge_id, %{nick: canceller}, channel}, pid: client}, state) do
    #IO.puts canceller <> " is cancelling a challenge with ID: " <> challenge_id <> " in " <> channel <> " from:"
    #IO.inspect client

    open_challenges = state.open_challenges
      |> Enum.filter(fn {a, b, c, d} -> {a, b, c, d} != {client, channel, challenge_id, canceller} end)

    {:noreply, %{state | open_challenges: open_challenges}}
  end


  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

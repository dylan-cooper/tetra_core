defmodule TetraIRC.ChallengeHandler do
  use GenServer

  defmodule State do
    defstruct open_challenges: [], #challenges opened by other people on IRC
              my_open_challenges: [], # challenges opened by this tetrabot on IRC
              client: nil
  end

  def start_link(client, name, state \\ %State{}) do
    GenServer.start_link(__MODULE__, [%{state | client: client}], name: name)
  end

  def init([state]) do
    ExIrc.Client.add_handler state.client, self
    {:ok, state}
  end

  def handle_call(:all_open_challenges, _from, state) do
    result = state.open_challenges
    {:reply, result, state}
  end

  #send an ACCEPT_CHALLENGE to the IRC chat
  def handle_cast({:accept_challenge, {challenge_id, channel}}, state) do
    msg = "ACCEPT_CHALLENGE:" <> challenge_id
    ExIrc.Client.msg(state.client, :privmsg, channel, msg)
    oc = state.open_challenges
      |> Enum.filter(fn {a, b, _} -> {a, b} != {channel, challenge_id} end)
    {:noreply, %{state | open_challenges: oc}}
  end

  #send an OPEN_CHALLENGE to the IRC chat
  def handle_cast({:open_challenge, {challenge_id, channel, pid}}, state) do
    msg = "OPEN_CHALLENGE:V1:" <> challenge_id
    ExIrc.Client.msg(state.client, :privmsg, channel, msg)
    my_open_challenges = state.my_open_challenges ++ [{channel, challenge_id, pid}]
    {:noreply, %{state | my_open_challenges: my_open_challenges}}
  end

  #send a CANCEL_CHALLENGE to the IRC chat
  def handle_cast({:cancel_challenge, {challenge_id, channel}}, state) do
    msg = "CANCEL_CHALLENGE:" <> challenge_id
    ExIrc.Client.msg(state.client, :privmsg, channel, msg)
    my_open_challenges = state.my_open_challenges
      |> Enum.filter(fn {a, b, _} -> {a, b} != {channel, challenge_id} end)
    {:noreply, %{state | my_open_challenges: my_open_challenges}}
  end

  #receive an OPEN_CHALLENGE from the IRC chat
  def handle_info({:received, "OPEN_CHALLENGE:V1:" <> challenge_id, %{nick: challenger}, channel}, state) do

    IO.puts challenger <> " sent V1 challenge in " <> channel
    open_challenges = state.open_challenges ++ [{channel, challenge_id, challenger}]
    {:noreply, %{state | open_challenges: open_challenges}}
  end

  #receive an ACCEPT_CHALLENGE from the IRC chat
  def handle_info({:received, "ACCEPT_CHALLENGE:" <> challenge_id, %{nick: acceptor}, channel}, state) do
    IO.puts acceptor <> " accepted challenge with ID: " <> challenge_id <> " in " <> channel
    
    if (state.my_open_challenges |> Enum.any?(fn {a, b, _} -> {a, b} == {channel, challenge_id} end)) do
      #the challenge_id matches a challenge opened by tetrabot

      #send message to the pid associated
      {_, _, pid} = Enum.find(state.my_open_challenges, fn {a, b, _} -> {a, b} == {channel, challenge_id} end)
      IO.inspect pid
      GenServer.cast(pid, {:found_acceptor, {challenge_id, acceptor, channel}})

      #remove from my_open_challenges
      my_open_challenges = state.my_open_challenges
        |> Enum.filter(fn {a, b, _} -> {a, b} != {channel, challenge_id} end)

      {:noreply, %{state | my_open_challenges: my_open_challenges}}
    else
      #a challenge created by someone else is being accepted by someone else

      open_challenges = state.open_challenges
        |> Enum.filter(fn {a, b, _} -> {a, b} != {channel, challenge_id} end)

      {:noreply, %{state | open_challenges: open_challenges}}
    end
  end

  def handle_info({:received, "CANCEL_CHALLENGE:" <> challenge_id, %{nick: canceller}, channel}, state) do
    IO.puts canceller <> " is cancelling a challenge with ID: " <> challenge_id <> " in " <> channel

    open_challenges = state.open_challenges
      |> Enum.filter(fn {a, b, c} -> {a, b, c} != {channel, challenge_id, canceller} end)

    {:noreply, %{state | open_challenges: open_challenges}}
  end


  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

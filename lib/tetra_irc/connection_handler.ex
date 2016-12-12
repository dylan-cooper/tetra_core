defmodule TetraIRC.ConnectionHandler do
  use GenServer

  def start_link(client, connection_details) do
    GenServer.start_link(__MODULE__, [%{connection_details: connection_details, client: client}])
  end

  def start_link(client, connection_details, subscriber) do
    GenServer.start_link(__MODULE__, [%{connection_details: connection_details, client: client, subscriber: subscriber}])
  end

  def init([state]) do
    ExIrc.Client.add_handler state.client, self
    ExIrc.Client.connect! state.client, state.connection_details.host, state.connection_details.port
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:all_connected_users, _from, state) do
    result = state.connection_details.channels
      |> Enum.map(fn c -> {ExIrc.Client.channel_users(state.client, c), c} end)
      |> Enum.map(fn {users, channel} -> Enum.map(users, fn x -> {x, channel} end) end)
      |> List.flatten
      |> Enum.filter(fn {user, _} -> user != state.connection_details.nick end)

    {:reply, result, state}
  end

  def handle_info({:connected, _server, _port}, state) do
    GenServer.call(:challenge_handler, {:add_client, state.client})
    ExIrc.Client.logon state.client, state.connection_details.pass, state.connection_details.nick, state.connection_details.user, state.connection_details.name
    {:noreply, state}
  end

  def handle_info(:logged_in, state) do
    state.connection_details.channels |> Enum.map(&ExIrc.Client.join state.client, &1)
    inform_subscriber(state)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_reason, state) do
    ExIrc.Client.quit state.client
  end

  defp inform_subscriber(%{subscriber: subscriber}) do
    Kernel.send(subscriber, :connection_complete)
  end

  defp inform_subscriber(_) do
    :ok
  end
end

defmodule TetraIRC.ConnectionHandler do
  use GenServer
  defmodule State do
    defstruct host: "chat.freenode.net",
              port: 6667, 
              pass: "tetrabotpass",
              nick: "tetrabot",
              user: "tetrabot",
              name: "Tetra Robot",
              channels: ["#tetra-testing", "#tetra-testing2"],
              client: nil
  end


  def start_link(client, name, state \\ %State{}) do
    GenServer.start_link(__MODULE__, [%{state | client: client}], name: name)
  end

  def init([state]) do
    ExIrc.Client.add_handler state.client, self
    ExIrc.Client.connect! state.client, state.host, state.port
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:all_connected_users, _from, state) do
    result = state.channels
      |> Enum.map(fn c -> {ExIrc.Client.channel_users(state.client, c), c} end)
      |> Enum.map(fn {users, channel} -> Enum.map(users, fn x -> {x, channel} end) end)
      |> List.flatten
      |> Enum.filter(fn {user, _} -> user != state.nick end)

    {:reply, result, state}
  end

  def handle_info({:connected, _server, _port}, state) do
    ExIrc.Client.logon state.client, state.pass, state.nick, state.user, state.name
    {:noreply, state}
  end

  def handle_info(:logged_in, state) do
    state.channels |> Enum.map(&ExIrc.Client.join state.client, &1)
    {:noreply, state}
  end

  #def handle_info({:joined, channel_name}, state) do
  #  new_channels = Enum.map(state.channels, fn(x) -> %{x | connected: x.connected || x.name == channel_name} end)
  #  {:noreply, %{state| channels: new_channels}}
  #end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

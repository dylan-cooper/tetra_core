defmodule TetraIRC.GameHandler do
  use GenServer

  defmodule State do
    defstruct channel: nil,
              opponent_nick: nil,
              client: nil
  end

  def start_link(client, state \\ %State{}) do
    GenServer.start_link(__MODULE__, [%{state | client: client}])
  end

  def init([state]) do
    ExIrc.Client.add_handler state.client, self
    {:ok, state}
  end

  def handle_cast({:set_channel_and_opponent, channel, opponent}, state) do
    {:noreply, %{state | opponent_nick: opponent, channel: channel}}
  end

  def handle_info({:received, msg, %{nick: sender}, channel}, state = %{channel: channel, opponent_nick: sender}) do
    IO.puts "Wooow: " <> msg
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

defmodule TetraIRC.GameHandlerSupervisor do
  use Supervisor
  import Supervisor.Spec

  def start_game_handler(channel, opponent) do
    {:ok, pid} = Supervisor.start_child(:gh_super, [])
    GenServer.cast(pid, {:set_channel_and_opponent, channel, opponent})
    {:ok, pid}
  end

  def init(client) do
    children = [
      worker(TetraIRC.GameHandler, [client], restart: :temporary)
    ]
    supervise children, strategy: :simple_one_for_one
  end

  def start_link(client) do
    Supervisor.start_link(__MODULE__, client, name: :gh_super)
  end
end

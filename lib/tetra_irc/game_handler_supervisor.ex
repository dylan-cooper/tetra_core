defmodule TetraIRC.GameHandlerSupervisor do
  use Supervisor
  import Supervisor.Spec

  def start_game_handler(client, channel, opponent) do
    {:ok, pid} = Supervisor.start_child(:gh_super, [client])
    GenServer.cast(pid, {:set_channel_and_opponent, channel, opponent})
    {:ok, pid}
  end

  def init(_) do
    children = [
      worker(TetraIRC.GameHandler, [], restart: :temporary)
    ]
    supervise children, strategy: :simple_one_for_one
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :gh_super)
  end
end

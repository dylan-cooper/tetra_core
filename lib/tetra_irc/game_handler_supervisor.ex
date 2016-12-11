defmodule TetraIRC.GameHandlerSupervisor do
  use Supervisor
  import Supervisor.Spec

  def start_game_handler(client, channel, opponent, game_key) do
    Supervisor.start_child(:gh_super, [client, channel, opponent, game_key])
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

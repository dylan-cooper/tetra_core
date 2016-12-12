defmodule TetraCore.GameSupervisor do
  use Supervisor
  import Supervisor.Spec

  def start_game(player1, player2) do
    Supervisor.start_child(:game_supervisor, [player1, player2])
  end

  def init(_) do
    children = [
      worker(TetraCore.Game, [], restart: :temporary)
    ]

    supervise children, strategy: :simple_one_for_one
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :game_supervisor) 
  end
end

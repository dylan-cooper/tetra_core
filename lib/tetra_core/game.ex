defmodule TetraCore.Game do
  use Supervisor
  import Supervisor.Spec

  def init(state) do
    children = [
      worker(TetraCore.Player, [state.player1], id: :player1),
      worker(TetraCore.Player, [state.player2], id: :player2),
      worker(TetraCore.Board, [])
    ]

    supervise children, strategy: :one_for_one
  end

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state)
  end
end

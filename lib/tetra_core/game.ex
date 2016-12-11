defmodule TetraCore.Game do
  use Supervisor
  import Supervisor.Spec

  def get_worker(game, worker_id) do
    {_, pid, _, _} = Supervisor.which_children(game)
      |> Enum.find(fn {id, _, _, _} -> id == worker_id end)
    pid
  end

  def init(state) do
    children = [
      worker(TetraCore.Player, [:player1, state.player1, self], id: :player1),
      worker(TetraCore.Player, [:player2, state.player2, self], id: :player2),
      worker(TetraCore.Board, [], id: :board)
    ]

    supervise(children, strategy: :one_for_one)
  end

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state)
  end
end

defmodule TetraIRC do
  use Supervisor
  import Supervisor.Spec

  def init(_) do

    children = [
      worker(TetraIRC.ChallengeHandler, []),
      supervisor(TetraIRC.ConnectionHandlerSupervisor, []),
      supervisor(TetraIRC.GameHandlerSupervisor, [])
    ]

    supervise children, strategy: :one_for_one
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :tetra_irc)
  end
end

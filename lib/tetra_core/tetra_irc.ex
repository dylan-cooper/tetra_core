defmodule TetraIRC do
  use Supervisor
  import Supervisor.Spec

  def init(_) do

    {:ok, client} = ExIrc.start_client!

    children = [
      worker(TetraIRC.ConnectionHandler, [client, :connection_handler]),
      worker(TetraIRC.ChallengeHandler, [client, :challenge_handler]),
      supervisor(TetraIRC.GameHandlerSupervisor, [client])
    ]

    supervise children, strategy: :one_for_one
  end

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state, name: :tetra_irc)
  end
end

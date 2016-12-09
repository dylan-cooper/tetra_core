defmodule TetraIRC.ConnectionHandlerSupervisor do
  use Supervisor
  import Supervisor.Spec

  def start_irc_connection(connection_details) do
    {:ok, client} = ExIrc.start_client!
    {:ok, pid} = Supervisor.start_child(:irc_connection_supervisor, [client, connection_details])
  end

  def start_irc_connection(connection_details, subscriber) do
    {:ok, client} = ExIrc.start_client!
    {:ok, pid} = Supervisor.start_child(:irc_connection_supervisor, [client, connection_details, subscriber])
  end
  
  def init(_) do
    children = [
      worker(TetraIRC.ConnectionHandler, [], restart: :temporary)
    ]
    supervise children, strategy: :simple_one_for_one
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: :irc_connection_supervisor)
  end
end

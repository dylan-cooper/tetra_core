defmodule TetraCore do
  use Application
  import Supervisor.Spec

  def go do
    start("", "")
  end

  def start(_start, _args) do

    children = [
      supervisor(TetraIRC, [[]]),
      supervisor(TetraCore.Matchmaker, [:matchmaker]),
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children , opts)
  end

end

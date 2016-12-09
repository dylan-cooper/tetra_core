defmodule TetraCore.Player do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    IO.inspect state
    {:ok, state}
  end

  def handle_call({:drop_piece, column}, _from, state) do
    IO.puts "In player, was asked to drop piece in column: " <> column
    {:reply, {:ok}, state}
  end
end

defmodule CLI.GameEventLoop do

  defmodule State do
    defstruct player_pid: nil,
              board_pid: nil
  end

  def start(match) do
    #Use match to start a game and initialize state
    IO.inspect match

    state = %State{}
    event_loop(state)
  end

  def event_loop(state) do
    input = IO.gets "Tetra > "
    input 
      |> String.strip(?\n)
      |> String.split(" ", parts: 2, trim: true)
      |> respond_to_input(state)
  end

  def respond_to_input(["quit"], _state) do
    :ok
  end

  def respond_to_input(["drop", column], state) do
    IO.puts "Should drop piece in " <> column
    reply = GenServer.call(state.player_pid, {:drop_piece, column})
    case reply do
      {:ok} ->
        IO.puts "Told this was okay in event loop"
      {:error} ->
        IO.puts "Told there was an error in event loop"
    end
    event_loop(state)
  end

  def respond_to_input(["display"], state) do
    IO.puts "Should display the board"
    event_loop(state)
  end

  def respond_to_input(["chat", message], state) do
    IO.puts "Would send chat message " <> message
    event_loop(state)
  end

  def respond_to_input(["help"], state) do
    IO.puts "Should display help menu"
    event_loop(state)
  end

  def respond_to_input(_, state) do
    IO.puts "Undefined command.  To review commands, use the help command"
    event_loop(state)
  end
end

defmodule CLI.MatchmakerEventLoop do

  defmodule State do
    defstruct something: nil,
              another_thing: nil
  end

  def start(_args, state \\ %State{}) do
    event_loop(state)
  end

  def event_loop(state) do
    input = IO.gets "Tetra Matchmaking > "
    input 
      |> String.strip(?\n)
      |> String.split(" ", trim: true)
      |> respond_to_input(state)
  end

  def respond_to_input(["quit"], _state) do
    :ok
  end

  def respond_to_input(["check"], state) do
    challenges = TetraIRC.ChallengeHandler.get_all_open_challenges
    case challenges do
      [] ->
        IO.puts "No challenges currently open."
      l ->
        print_challenge({nil, "Channel", "ID", "Name"})

        String.duplicate "-", 60 |> IO.puts

        l |> Enum.each(fn c -> c |> print_challenge end)
    end
    event_loop(state)
  end

  def respond_to_input(["open", channel, challenge_id], _state) do
    IO.puts "Should open a challenge in channel: " <> channel <> " with id: " <> challenge_id
    [client | _] = TetraIRC.ChallengeHandler.get_clients
    TetraIRC.ChallengeHandler.open_challenge_async(client, channel, challenge_id, self)
    IO.write "Waiting for someone to accept this challenge: "
    wait_for_acceptor
  end

  def respond_to_input(["accept", challenge_id], state) do
    result = TetraIRC.ChallengeHandler.accept_challenge challenge_id
    case result do
      {:ok, msg} ->
        {:ok, msg}
      {:challenge_id_not_found, _} ->
        IO.puts "Did not find a challenge with that ID"
        event_loop(state)
    end
  end

  def respond_to_input(["help"], state) do
    IO.puts "accept <challenge_id> - Accept the challenge"
    IO.puts "check - Check challenges that are currently open"
    IO.puts "open <channel> <challenge_id> - Open a new challenge in a given channel"
    IO.puts "quit - Quit the program"
    event_loop(state)
  end

  def respond_to_input(_, state) do
    IO.puts "Undefined command.  To review commands, use the help command"
    event_loop(state)
  end

  defp print_challenge ({_, channel, id, name}) do
    IO.write String.pad_trailing(name, 20)
    IO.write String.pad_trailing(id, 20)
    IO.write String.pad_trailing(channel, 20)
    IO.write "\n"
  end

  defp wait_for_acceptor(n \\ 0) do
    chars = "|/-\\"
    receive do
      {:found_acceptor, {client, channel, _challenge_id, nick}} ->
        IO.write "\b\n"
        IO.puts "The challenge was accepted by: " <> nick
        {:ok, {client, channel, nick}}
      msg ->
        IO.puts :stderr, "Unexpected message"
        IO.inspect msg
        wait_for_acceptor(n)
    after
      200 ->
        IO.write "\b" <> String.at(chars, n)
        rem(n + 1, 4) |> wait_for_acceptor
    end
  end
end

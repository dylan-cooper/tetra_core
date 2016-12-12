defmodule CLI.MatchmakerEventLoop do

  defmodule State do
    defstruct something: nil,
              another_thing: nil
  end

  def start(:bot) do
    :bot
  end

  def start(_args) do

    state = %State{}
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
    :quit
  end

  def respond_to_input(["check"], state) do
    TetraIRC.ChallengeHandler.get_all_open_challenges
      |> display_challenges

    event_loop(state)
  end

  def respond_to_input(["open", channel, challenge_id], _state) do
    IO.puts "Opening a challenge with id: " <> challenge_id
    [client | _] = TetraIRC.ChallengeHandler.get_clients
    TetraIRC.ChallengeHandler.open_challenge_async(client, channel, challenge_id, self)
    IO.write "Waiting for someone to accept this challenge: "
    wait_for_acceptor
  end

  def respond_to_input(["open", channel], state) do
    respond_to_input(["open", channel, to_string(:os.system_time(:seconds))], state)
  end

  def respond_to_input(["accept", challenge_id], state) do
    result = TetraIRC.ChallengeHandler.accept_challenge challenge_id
    case result do
      {:ok, {client, channel, nick}} ->
        {:ok, {client, channel, nick, challenge_id, false}}
      {:challenge_id_not_found, _} ->
        IO.puts "Did not find a challenge with that ID"
        event_loop(state)
    end
  end

  def respond_to_input(["accept"], state) do
    case TetraIRC.ChallengeHandler.get_any_open_challenge do
      :no_open_challenges ->
        IO.puts "Did not find any open challenges"
        event_loop(state)
      {_, _, challenge_id, _} ->
        respond_to_input(["accept", challenge_id], state)
    end
  end

  def respond_to_input(["help"], state) do
    IO.puts "accept <challenge_id> - Accept the challenge"
    IO.puts "accept - Accept any open challenge"
    IO.puts "check - Check challenges that are currently open"
    IO.puts "open <channel> <challenge_id> - Open a new challenge in specified channel"
    IO.puts "open <channel> - Open a new challenge in specified channel with generated key"
    IO.puts "quit - Quit the program"
    event_loop(state)
  end

  def respond_to_input(_, state) do
    IO.puts "Undefined command.  To review commands, use the help command"
    event_loop(state)
  end

  defp wait_for_acceptor(n \\ 0) do
    chars = "|/-\\"
    receive do
      {:found_acceptor, {client, channel, challenge_id, nick}} ->
        IO.write "\b\n"
        IO.puts "The challenge was accepted by: " <> nick
        {:ok, {client, channel, nick, challenge_id, true}}
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

  defp display_challenges([]) do
    IO.puts "No challenges currently open."
  end

  defp display_challenges(challenges) do
    display_challenge({nil, "Channel", "ID", "Name"})
    String.duplicate("-", 60) |> IO.puts
    challenges |> Enum.each(fn c -> c |> display_challenge end)
  end

  defp display_challenge ({_, channel, id, name}) do
    IO.write String.pad_trailing(name, 20)
    IO.write String.pad_trailing(id, 20)
    IO.write String.pad_trailing(channel, 20)
    IO.write "\n"
  end
end

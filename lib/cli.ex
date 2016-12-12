defmodule CLI do
  def main(args) do
    try do
      args
        |> parse_args
        |> CLI.ConnectingEventLoop.start
        |> CLI.MatchmakerEventLoop.start
        |> CLI.GameEventLoop.start
    rescue
      e in OptionParser.ParseError ->
        IO.puts "There was an error while parsing the command line arguments."
        IO.inspect e
    end
  end

  defp parse_args(args) do
    {parsed, rest}  = args |>
      OptionParser.parse!(
        strict: [
          host: :string,
          user: :string,
          nick: :string,
          pass: :string,
          name: :name,
          bot:  :boolean,
        ]
      )

    {Enum.into(parsed, %{}), rest}
  end
end

defmodule CLI do
  def main(args) do
    ##TODO: determine what args make sense
    args
      |> parse_args
      |> CLI.ConnectingEventLoop.start
      |> CLI.MatchmakerEventLoop.start
      |> CLI.GameEventLoop.start
  end

  defp parse_args(args) do
    #{options, args, errors} = args |> 
    args |>
      OptionParser.parse(
        strict: [
          host: :string,
          port: :integer,
          channel: :string,
          nick: :string,
          pass: :string,
        ]
      )
  end
end

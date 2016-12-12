defmodule CLI.Helpers do

  def wait_for(message, stop?, callback) when is_function(stop?) and is_function(callback) do
    IO.write message <> ": \\"
    do_wait_for(stop?, callback, 0)
    
  end

  def do_wait_for(stop?, callback, n) when is_function(stop?) and is_function(callback) do
    chars = "|/-\\"
    receive do
      msg ->
        if (stop?.(msg)) do
          callback.(msg)
        else
          callback.(msg)
          do_wait_for(stop?, callback, rem(n + 1, 4))
        end
    after
      200 -> 
        IO.write "\b" <> String.at(chars, n)
        do_wait_for(stop?, callback, rem(n + 1, 4))
    end
  end
end

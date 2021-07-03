defmodule Sandbox do
  def human_guess do
    input = IO.gets("> Enter a number between 1 and 100: ") |> String.trim()
    if input in ["f", "q"] do
      IO.puts("Forfeited.")
    else
      try do
        String.to_integer(input)
      rescue
        ArgumentError ->
          IO.puts("Invalid number, or f || q")
          human_guess()
      end
    end
  end
end
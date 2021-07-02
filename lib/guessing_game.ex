defmodule GuessingGame do
  @moduledoc """
  Main game functionality.
  """
  @answer Enum.random(1..100)

  @spec guess(integer) :: atom()
  def guess(x) when x > @answer, do: :lower
  def guess(x) when x < @answer, do: :higher
  def guess(x) when x == @answer, do: :success

  @spec answer :: integer()
  def answer, do: @answer
end

defmodule GuessingGame.LeaderBoard do
  @leaderboard :leaderboard

  def init do
    unless :ets.whereis(@leaderboard) == :undefined do
      :ets.delete(@leaderboard)
    end
    :ets.new(@leaderboard, [:set, :public, :named_table])
  end

  def add_player(pid, mode, guesses) do
    :ets.insert(@leaderboard, {pid, mode, guesses})
  end

  def get_player(pid) do
    :ets.lookup(@leaderboard, pid)
  end

  def score do
    :ets.tab2list(@leaderboard)
  end

  @spec register_player(pid) :: nil
  def register_player(player) do
    add_player(player, :playing, 0)
  end
end

defmodule GuessingGame.Session do

  def setup(player_count \\ 2) do
    # Create players
    players = Enum.map(1..player_count, fn _ -> GuessingGame.Player.new end)
              |> Enum.into([], fn {_, pid} -> pid end)

    # Initialize leaderboard
    GuessingGame.LeaderBoard.init()

    # Register players with leaderboard
    players |> Enum.each(fn player -> GuessingGame.LeaderBoard.register_player(player) end)

    # First round
    players = Enum.map(players, fn player -> GuessingGame.Player.guess(player) end)
    players
#    IO.puts(players)
#    new_round(players)
  end

  def new_round(players) do
    if length(players) > 0 do
      Enum.each(players, fn player -> GuessingGame.Player.add_player end)
#      players_score = Enum.each(players, fn player -> GuessingGame.Player end)
#      players = tally_score(players_score)
#      new_round(players)
    end
#    IO.puts(GuessingGame.LeaderBoard.score)
#    IO.puts("Game over")
  end

#  @doc """
#  Tallys score and removes players who have won from the list of active players
#  """
#  def tally_score(players_score) do
#    players_score |> Enum.each(fn {player, } -> GuessingGame.LeaderBoard.add_player() end)
#    players |> Enum.filter
#  end
end

defmodule GuessingGame.Player do
  @moduledoc """
  {:ok, pid} = GuessingGame.Player.new
  GuessingGame.Player.count pid
"""
  use GenServer

  def new do
    GenServer.start_link(__MODULE__, :ok)
  end

  def guess(pid, number \\ Enum.random(1..100)) do
    GenServer.call(pid, %{guess: number, player: pid})
  end

  @doc """
  GuessingGame.LeaderBoard.init()
  {:ok, pid} = GuessingGame.Player.new
  result = GuessingGame.Player.next_turn(pid)
  result = GuessingGame.Player.guess(pid, result)
  """
  def next_turn(pid, result \\ %{hint: :first, mode: :playing}) do
    case result.mode do
      :playing ->
        case result.hint do
          :higher ->
            guess(pid, Enum.random((hd result.stats.guesses) + 1..100))
          :lower ->
            guess(pid, Enum.random((hd result.stats.guesses) - 1..1))
          _ ->
            guess(pid)
        end
      :winner ->
        IO.puts("This player has already won. No further turns required.")
    end
  end

  def init(:ok) do
    {:ok, %{attempts: 0, guesses: []}}
  end

  def handle_call(%{guess: guess, player: player}, _from, stats) do
    case guess == GuessingGame.answer do
      false ->
        new_stats = update_stats(stats, guess)
        {:reply, %{mode: :playing, hint: GuessingGame.guess(guess), player: player, stats: new_stats}, new_stats}
      true ->
        {:reply, %{mode: :winner, player: player, stats: stats}, stats}
      end
  end

  defp update_stats(stats, guess) do
      %{attempts: stats.attempts + 1, guesses: [guess | stats.guesses]}
  end
end
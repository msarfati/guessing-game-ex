defmodule GuessingGame do
  @moduledoc """
  Main game functionality.
  """
  @answer Enum.random(1..100)  # TODO: store in ETS

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
    :ets.lookup(@leaderboard, pid) |> List.first
  end

  def forfeiters do
    :ets.tab2list(@leaderboard)
    |> Enum.filter( fn {_pid, mode, _attempt} ->  mode == :forfeit end)
    |> Enum.map( fn {pid, mode, attempt} -> {GuessingGame.Humans.get_name(pid), mode, attempt} end)
  end

  def score do
    :ets.tab2list(@leaderboard)
    |> Enum.sort( fn {_, _, score1}, {_, _, score2} -> score1 <= score2  end)
  end

  def score_pretty do
    IO.write("Score\tPlayer\n")
    Enum.each(score(), fn player ->
      {pid, mode, attempts} = player
      name = GuessingGame.Humans.get_name(pid) || "AI_#{String.split((inspect pid), ".") |> Enum.fetch!(1)}"
      if mode == :winner do
        IO.write("#{attempts}\t #{name}\n")
      end
    end)
    if (length forfeiters()) > 0 do
      IO.puts("Forfeiters: #{inspect forfeiters()}")
    end
  end

  @spec register_player(pid) :: nil
  def register_player(player) do
    add_player(player, :playing, 0)
  end

  def total_rounds do
    score()
    |> Enum.map(fn {_pid, _mode, attempt} -> attempt end)
    |> Enum.max()
  end

  def player_count do
    score() |> length
  end

  def game_stats do
    %{answer: GuessingGame.answer, total_rounds: total_rounds(), number_of_players: player_count()}
  end
end

defmodule GuessingGame.Humans do
  @humans :humans

  def init do
    unless :ets.whereis(@humans) == :undefined do
      :ets.delete(@humans)
    end
    :ets.new(@humans, [:set, :public, :named_table])
  end

  def add(pid, name) do
    :ets.insert(@humans, {pid, name})
  end

  def get(pid) do
    :ets.lookup(@humans, pid) |> List.first
  end

  def get_name(pid) do
    human = get(pid)
    if human, do: elem(human, 1), else: nil
  end

  def all do
    :ets.tab2list(@humans)
  end

  @doc """
  General handler for human keyboard inputs.
  """
  def parse_response(raw_input) do
    input = String.trim(raw_input)
    if input in ["f", "F", "q", "Q"] do
      exit(:shutdown)
    else
      try do
        number = String.to_integer(input)
        {:result, number}
      rescue
        ArgumentError ->
          IO.puts("Invalid number. F or Q to quit")
          {:error}
      end
    end
  end
end

defmodule GuessingGame.Menu do
  @titlescreen """
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░         ░░░░░░░░░░
    ▒▒  ▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    ▒  ▒▒▒▒▒▒▒▒▒▒▒   ▒▒   ▒▒▒▒   ▒▒▒▒▒▒     ▒▒▒     ▒▒▒▒▒▒   ▒   ▒▒▒▒     ▒▒▒  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒    ▒   ▒   ▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒   ▒▒▒
    ▓   ▓▓▓▓▓▓▓▓▓▓   ▓▓   ▓▓  ▓▓▓   ▓▓   ▓▓▓▓▓   ▓▓▓▓▓   ▓▓   ▓▓   ▓   ▓▓   ▓   ▓▓▓▓▓▓▓▓▓▓▓   ▓▓   ▓▓▓   ▓▓  ▓▓   ▓▓  ▓▓▓   ▓▓▓▓▓▓       ▓▓▓▓▓  ▓   ▓
    ▓   ▓▓▓      ▓   ▓▓   ▓         ▓▓▓▓    ▓▓▓▓    ▓▓   ▓▓   ▓▓   ▓  ▓▓▓   ▓   ▓▓▓      ▓   ▓▓▓   ▓▓▓   ▓▓  ▓▓   ▓         ▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓
    ▓▓   ▓▓▓▓  ▓▓▓   ▓▓   ▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓   ▓   ▓▓   ▓▓   ▓    ▓   ▓▓   ▓▓▓▓  ▓▓▓   ▓▓▓   ▓▓▓   ▓▓  ▓▓   ▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓  ▓▓   ▓
    ███      ███████      ███     ████      ██      ██   █    ██   █████   ████      ███████   █    █    ██  ██   ███     ████  ██         █   ███
    ██████████████████████████████████████████████████████████████████    ███████████████████████████████████████████████████████████████████████████
    by Michael Sarfati ( github.com/msarfati )
  """
  @options """
  1) Single player
  2) Multiplayer (multiple humans)
  3) Spectator mode
  4) Quit
  """

  def query(:players, current, total) do
    IO.puts("Enter name for player ##{length(current) + 1} of #{total}:")
    current = [IO.gets("> ") |> String.trim() |> String.to_atom | current]
    if length(current) == total do
      current
    else
      query(:players, current, total)
    end
  end

  def query(:npc_count) do
    IO.puts("How many enemy AI opponents? Theoretically infinite, limited only by your imagination (and hardware)")
    response = IO.gets("> ")
    case GuessingGame.Humans.parse_response(response) do
      {:result, number} -> number
      _ -> query(:npcs)
    end
  end

  def menu(mode \\ :main)
  def menu(:main) do
    IO.puts(@titlescreen)
    IO.puts(@options)
    user_choice = IO.gets("> ")
    case GuessingGame.Humans.parse_response(user_choice) do
      {:result, number} ->
        case number do
          1 -> menu(:single)
          2 -> menu(:multiplayer)
          3 -> menu(:spectate)
          4 -> exit(:shutdown)
          _ -> menu(:main)
        end
      {:error} -> menu(:main)
    end
  end

  def menu(:single) do
    humans = query(:players, [], 1)
    npc_count = query(:npc_count)
    menu(:start, humans, npc_count)
  end

  def menu(:multiplayer) do
    IO.puts("How many human players?")
    response = IO.gets("> ")
    total_humans = case GuessingGame.Humans.parse_response(response) do
      {:result, number} -> number
      _ -> query(:npcs)
    end
    humans = query(:players, [], total_humans)
    npc_count = query(:npc_count)
    menu(:start, humans, npc_count)
  end

  def menu(:spectate) do
    IO.puts("Spectator mode.")
    npc_count = query(:npc_count)
    menu(:start, nil, npc_count)
  end

  def menu(:start, humans, npc_count) do
    IO.puts("""
                ╔═══╗╔═══╗╔═╗╔═╗╔═══╗    ╔═══╗╔════╗╔═══╗╔═══╗╔════╗╔╗
                ║╔═╗║║╔═╗║║║╚╝║║║╔══╝    ║╔═╗║║╔╗╔╗║║╔═╗║║╔═╗║║╔╗╔╗║║║
      ╔═╗╔═╗    ║║ ╚╝║║ ║║║╔╗╔╗║║╚══╗    ║╚══╗╚╝║║╚╝║║ ║║║╚═╝║╚╝║║╚╝║║    ╔═╗╔═╗
      ╚═╝╚═╝    ║║╔═╗║╚═╝║║║║║║║║╔══╝    ╚══╗║  ║║  ║╚═╝║║╔╗╔╝  ║║  ╚╝    ╚═╝╚═╝
    ╔╗╔═╗╔═╗    ║╚╩═║║╔═╗║║║║║║║║╚══╗    ║╚═╝║ ╔╝╚╗ ║╔═╗║║║║╚╗ ╔╝╚╗ ╔╗    ╔═╗╔═╗╔╗
    ╚╝╚═╝╚═╝    ╚═══╝╚╝ ╚╝╚╝╚╝╚╝╚═══╝    ╚═══╝ ╚══╝ ╚╝ ╚╝╚╝╚═╝ ╚══╝ ╚╝    ╚═╝╚═╝╚╝
""")
    GuessingGame.Session.setup(humans, npc_count)
  end
end

defmodule GuessingGame.Session do
  def setup_humans(humans) do
    Enum.map(humans,
      fn name ->
        {_, pid} = GuessingGame.Player.new
        GuessingGame.Humans.add(pid, name)
        pid
      end)
  end

  def setup(humans \\ nil, npc_count \\ 1) do
    # Setup trackers
    GuessingGame.Humans.init()
    GuessingGame.LeaderBoard.init()

    # Create players
    npcs = Enum.map(1..npc_count, fn _ -> GuessingGame.Player.new end)
           |> Enum.into([], fn {_, pid} -> pid end)

    humans = if humans, do: setup_humans(humans), else: []

    players = humans ++ npcs

    # Register players with leaderboard
    players |> Enum.each(fn player -> GuessingGame.LeaderBoard.register_player(player) end)

    # First round
    players = Enum.map(players, fn player -> GuessingGame.Player.next_turn(player) end)
    players = tally_score(players)

    # Start main game loop
    new_round(players)
  end

  def new_round(players) do
    if length(players) > 0 do
      players_score = Enum.map(players, fn player -> GuessingGame.Player.next_turn(player.player, player) end)
      tally_score(players_score) |> new_round()
    else
      gameover()
    end
  end

  @doc """
  Tallys score and removes players who have won from the list of active players
  """
  def tally_score(players) do
    # Update leaderboard
    Enum.each(players,
      fn player ->
        GuessingGame.LeaderBoard.add_player(player.player, player.mode, player.stats.attempts) end)

#    # Display running score
#    IO.puts("Running score: #{inspect GuessingGame.LeaderBoard.score}")

    # End processes of winners
    Enum.filter(players, fn player -> player.mode in [:winner, :forfeit] end)
      |> Enum.each(fn player -> GuessingGame.Player.stop(player.player) end)
    # Filter out winners and forfeitters
    Enum.filter(players, fn player -> player.mode == :playing end)
  end

  def gameover do
    """
                  ╔═══╗                           ╔═══╗
                  ║╔═╗║                           ║╔═╗║
        ╔═╗╔═╗    ║║ ╚╝╔══╗ ╔╗╔╗╔══╗    ╔═╗╔═╗    ║║ ║║╔╗╔╗╔══╗╔═╗    ╔═╗╔═╗
        ╚═╝╚═╝    ║║╔═╗╚ ╗║ ║╚╝║║╔╗║    ╚═╝╚═╝    ║║ ║║║╚╝║║╔╗║║╔╝    ╚═╝╚═╝
    ╔╗╔╗╔═╗╔═╗    ║╚╩═║║╚╝╚╗║║║║║║═╣    ╔═╗╔═╗    ║╚═╝║╚╗╔╝║║═╣║║     ╔═╗╔═╗╔╗╔╗
    ╚╝╚╣╚═╝╚═╝    ╚═══╝╚═══╝╚╩╩╝╚══╝    ╚═╝╚═╝    ╚═══╝ ╚╝ ╚══╝╚╝     ╚═╝╚═╝╚╣╚╝
       ╝                                                                     ╝
""" |> IO.puts()
    GuessingGame.LeaderBoard.score_pretty
    GuessingGame.LeaderBoard.game_stats
  end
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

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def guess(pid, number \\ Enum.random(1..100)) do
    GenServer.call(pid, %{guess: number, player: pid})
  end

  def forfeit(pid) do
    GenServer.call(pid, %{player: pid, mode: :forfeit})
  end

  def human_guess(pid, result) do
    IO.puts("#{GuessingGame.Humans.get_name(pid)}'s turn. GO!")
    unless result.hint == :first, do: IO.puts("Hint: try a number that is #{result.hint}.")
    input = IO.gets("> Enter a number between 1 and 100: ")
    case GuessingGame.Humans.parse_response(input) do
      {:quit} -> forfeit(pid)
      {:result, number} -> guess(pid, number)
      {:error} -> human_guess(pid, result)
      end
  end

  def next_turn(pid, result \\ %{hint: :first, mode: :playing})
  def next_turn(pid, result) when pid != self() do
    case result.mode do
      :playing ->
        if GuessingGame.Humans.get(pid) do
          human_guess(pid, result)
        else
          case result.hint do
            :higher ->
              guess(pid, Enum.random((hd result.stats.guesses) + 1..100))
            :lower ->
              guess(pid, Enum.random((hd result.stats.guesses) - 1..1))
            _ ->
              guess(pid)
          end
        end
      :forfeit ->
        IO.puts("This player has forfeited the game.")
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
  def handle_call(%{mode: :forfeit, player: player}, _from, stats) do
    {:reply, %{mode: :forfeit, player: player, stats: stats}, stats}
  end

    def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  defp update_stats(stats, guess) do
      %{attempts: stats.attempts + 1, guesses: [guess | stats.guesses]}
  end
end

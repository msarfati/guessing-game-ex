defmodule GuessingGameTest do
  use ExUnit.Case
  doctest GuessingGame

  test "GuessingGame proper functionality" do

  end

  test "Basic GuessingGame.Player functionality" do
    {:ok, pid} = GuessingGame.Player.new
    assert Process.alive?(result.player)
    result = GuessingGame.Player.next_turn(pid)
    assert Process.alive?(result.player)
  end
end

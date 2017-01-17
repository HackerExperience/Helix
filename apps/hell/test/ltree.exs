defmodule HELL.LTreeTest do
  use ExUnit.Case

  alias HELL.TestHelper.Random
  alias HELL.LTree

  defp random_path() do
    size = Random.number(1..20)
    alphabet = HELL.TestHelper.Random.Alphabet.Alphanum.alphabet
    Enum.map(0..size, fn _ ->
      length = Random.number(1..20)
      Random.string(length: length, alphabet: alphabet)
    end)
  end

  describe "cast" do
    test "yielding identity when is_list" do
      input = random_path()
      assert {:ok, ^input} = LTree.cast(input)
    end

    test "converting to list when is_binary" do
      input = random_path()
      {:ok, str_input} = LTree.dump(input)
      assert {:ok, ^input} = LTree.cast(str_input)
    end
  end

  describe "load" do
    test "yielding identity when is_list" do
      input = random_path()
      assert {:ok, ^input} = LTree.load(input)
    end

    test "converting to list when is_binary" do
      input = random_path()
      {:ok, str_input} = LTree.dump(input)
      assert {:ok, ^input} = LTree.load(str_input)
    end
  end

  describe "dump" do
    test "rejecting whitespace" do
      assert :error == LTree.dump([" "])
    end

    test "rejecting empty strings" do
      assert :error == LTree.dump([""])
    end

    test "accepting valid structures" do
      for _ <- 0..Random.number(0..200) do
        assert {:ok, _} = LTree.dump(random_path())
      end
    end
  end
end
defmodule HELL.LTreeTest do
  use ExUnit.Case

  alias HELL.TestHelper.Random
  alias HELL.LTree

  defp generate_random_path() do
    size = Random.number(1..20)
    alphabet = HELL.TestHelper.Random.Alphabet.Alphanum.alphabet
    Enum.map(0..size, fn _ ->
      length = Random.number(1..20)
      Random.string(length: length, alphabet: alphabet)
    end)
  end

  defp generate_random_repeat(content) do
    length = 0..Random.number(1..10)
    Enum.map(length, fn _ -> content end)
  end

  describe "casting" do
    test "is identity when list is a list" do
      list = generate_random_path()

      assert {:ok, ^list} = LTree.cast(list)
    end

    test "converts binary to list" do
      list = generate_random_path()
      {:ok, str} = LTree.dump(list)

      assert {:ok, ^list} = LTree.cast(str)
    end
  end

  test "loading converts binary to list" do
    list = generate_random_path()
    {:ok, str} = LTree.dump(list)

    assert {:ok, ^list} = LTree.load(str)
  end

  describe "dumping" do
    test "accepts lists containing valid binaries" do
      for _ <- 0..Random.number(0..20) do
        list = generate_random_path()

        assert {:ok, _} = LTree.dump(list)
      end
    end

    test "rejects lists containing whitespaces" do
      for _ <- 0..Random.number(0..20) do
        list = generate_random_repeat(" ")

        assert :error == LTree.dump(list)
      end
    end

    test "rejects lists containing empty binaries" do
      for _ <- 0..Random.number(0..20) do
        list = generate_random_repeat("")

        assert :error == LTree.dump(list)
      end
    end

    test "rejects empty lists" do
      assert :error == LTree.dump([])
    end
  end
end
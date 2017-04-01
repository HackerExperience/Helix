defmodule HELL.DirectoryTest do

  use ExUnit.Case, async: true

  alias HELL.LTree
  alias HELL.Directory

  @moduletag :unit

  @test_strings [
    "/foo bar baz",
    "/foo/bar/baz",
    "/.foo/bar/baz!",
    "/f(oo)/ b a r / !#! baz - (1st copy)"
  ]

  test "converts an input string into a valid LTree path" do
    Enum.each(@test_strings, fn string ->
      {:ok, representation} = Directory.cast(string)
      %Directory{path: ltree_path} = representation

      assert LTree.valid_path?(ltree_path)
    end)
  end

  test "it's representation can be converted back to it's original string" do
    Enum.each(@test_strings, fn string ->
      {:ok, representation} = Directory.cast(string)

      %Directory{path: ltree_path} = representation

      refute string == ltree_path
      assert string == to_string(representation)
    end)
  end

  test "paths always start with a slash" do
    input = "foo/bar"

    {:ok, representation} = Directory.cast(input)

    assert "/" <> _ = to_string(representation)
  end

  test "paths never end with a slash" do
    input = "/foo/bar/"

    {:ok, representation} = Directory.cast(input)

    refute "/" == String.at(to_string(representation), -1)
  end
end

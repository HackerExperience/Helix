defmodule HELL.UUIDTest do
  use ExUnit.Case

  alias HELL.UUID, as: HUUID

  describe "create/2" do
    test "valid format" do
      assert "ff00" <> _ = HUUID.create("ff")
      assert "ffa0" <> _ = HUUID.create("ff", meta1: "a")
      assert "ff0b" <> _ = HUUID.create("ff", meta2: "b")
      assert "ffab" <> _ = HUUID.create("ff", meta1: "a", meta2: "b")
    end

    test "invalid format" do
      assert nil == HUUID.create("ue")
      assert nil == HUUID.create("ff", meta1: "u")
      assert nil == HUUID.create("ff", meta2: "w")
      assert nil == HUUID.create("ff", meta1: "u", meta2: "e")
    end
  end

  describe "header/2" do
    test "correct format" do
      assert "ff00" = HUUID.header("ff")
      assert "ffa0" = HUUID.header("ff", meta1: "a")
      assert "ff0b" = HUUID.header("ff", meta2: "b")
      assert "ffab" = HUUID.header("ff", meta1: "a", meta2: "b")
    end

    test "invalid format" do
      assert nil == HUUID.header("ue")
      assert nil == HUUID.header("ff", meta1: "u")
      assert nil == HUUID.header("ff", meta2: "w")
      assert nil == HUUID.header("ff", meta1: "u", meta2: "e")
    end
  end

  describe "merge_header/2" do
    test "prebuild header" do
      header = HUUID.header("ff", meta1: "a", meta2: "b")
      assert "ffab" <> _ = HUUID.merge_header(header)
    end

    test "handmade header" do
      header = "abcdef"
      assert "abcdef" <> _ = HUUID.merge_header(header)
    end

    test "empty header" do
      assert is_binary HUUID.merge_header("")
    end

    test "invalid header" do
      header = HUUID.header("ue")
      assert nil == HUUID.merge_header(header)
    end
  end
end

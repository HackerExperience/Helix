defmodule HELL.UUIDTest do
  use ExUnit.Case

  alias HELL.UUID, as: HUUID

  describe "create/2" do
    test "valid format" do
      assert {:ok, "ff00" <> _} = HUUID.create("ff")
      assert {:ok, "ffa0" <> _} = HUUID.create("ff", meta1: "a")
      assert {:ok, "ff0b" <> _} = HUUID.create("ff", meta2: "b")
      assert {:ok, "ffab" <> _} = HUUID.create("ff", meta1: "a", meta2: "b")
    end

    test "invalid format" do
      assert :error == HUUID.create("ue")
      assert :error == HUUID.create("ff", meta1: "u")
      assert :error == HUUID.create("ff", meta2: "w")
      assert :error == HUUID.create("ff", meta1: "u", meta2: "e")
    end
  end

  describe "create!/2" do
    test "success" do
      assert "ff00" <> _ = HUUID.create!("ff")
    end

    test "failure" do
      assert_raise ArgumentError, fn ->
        HUUID.create!("ue")
      end
    end
  end

  describe "debug/1" do
    test "parsing valid information" do
      a = "ff"
      b = "a"
      c = "b"
      assert {:ok, uuid} = HUUID.create(a, meta1: b, meta2: c)
      assert %{domain: ^a, meta1: ^b, meta2: ^c} = HUUID.debug(uuid)
    end

    test "parsing invalid information" do
      assert_raise MatchError, fn ->
        HUUID.debug("")
      end
    end
  end
end

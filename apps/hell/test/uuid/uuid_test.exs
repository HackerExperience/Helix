defmodule HELL.UUIDTest do
  use ExUnit.Case

  alias HELL.UUID, as: HUUID

  describe "create/2" do
    test "id length without params" do
      uuid = HUUID.create("ff")
      assert String.length(uuid) == 36
    end

    test "id length with meta1" do
      uuid = HUUID.create("ff", meta1: "1")
      assert String.length(uuid) == 36
    end

    test "id length with meta2" do
      uuid = HUUID.create("ff", meta2: "2")
      assert String.length(uuid) == 36
    end

    test "id length with both metas" do
      uuid = HUUID.create("ff", meta1: "1", meta2: "1")
      assert String.length(uuid) == 36
    end

    test "domain inclusion" do
      uuid = HUUID.create("ff")
      assert <<"ff", uuid::binary>> = uuid
    end

    test "domain and meta1 inclusion" do
      uuid = HUUID.create("ff", meta1: "1")
      assert <<"ff1", uuid::binary>> = uuid
    end

    test "domain and meta2 inclusion" do
      uuid = HUUID.create("ff", meta2: "2")
      assert <<"ff2", uuid::binary>> = uuid
    end

    test "domain and metas ordering" do
      uuid = HUUID.create("ff", meta1: "1", meta2: "2")
      assert <<"ff12", uuid::binary>> = uuid
    end

    test "domain and metas ordering with variable length" do
      uuid = HUUID.create("ff", meta1: "425366", meta2: "1141413")
      assert <<"ff425366-1141-413", uuid::binary>> = uuid
    end

    test "domain length is too small" do
      assert {:uuid_format_error, :min_length} == catch_throw(HUUID.create(""))
      assert {:uuid_format_error, :min_length} == catch_throw(HUUID.create("a"))
    end

    test "domain length is too big" do
      assert {:uuid_format_error, :max_length} == catch_throw(HUUID.create("fff"))
    end

    test "domain is not hex" do
      assert {:uuid_format_error, {:invalid_hex, :domain}} == catch_throw(HUUID.create("wo"))
    end

    test "meta1 is not hex" do
      assert {:uuid_format_error, {:invalid_hex, :meta1}} == catch_throw(HUUID.create("ff", meta1: "wow"))
    end

    test "meta2 is not hex" do
      assert {:uuid_format_error, {:invalid_hex, :meta2}} == catch_throw(HUUID.create("ff", meta2: "wow"))
    end
  end

  describe "merge/2" do
    test "correct merge" do
      str = HUUID.merge("ff", "abcd")
      assert "ffcd" = str
    end
  end
end

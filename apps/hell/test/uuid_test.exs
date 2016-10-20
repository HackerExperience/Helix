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
      assert <<"ff", _::binary>> = HUUID.create("ff")
    end

    test "domain and meta1 inclusion" do
      assert <<"ff1", _::binary>> = HUUID.create("ff", meta1: "1")
    end

    test "domain and meta2 inclusion" do
      assert <<"ff2", _::binary>> = HUUID.create("ff", meta2: "2")
    end

    test "domain and metas ordering" do
      assert <<"ff12", _::binary>> = HUUID.create("ff", meta1: "1", meta2: "2")
    end

    test "domain and metas ordering with variable length" do
      assert <<"ff425366-1141-413", uuid::binary>> = HUUID.create("ff", meta1: "425366", meta2: "1141413")
    end

    test "domain length is too small" do
      assert {:invalid_uuid, :domain, :length} == catch_throw(HUUID.create(""))
      assert {:invalid_uuid, :domain, :length} == catch_throw(HUUID.create("a"))
    end

    test "domain length is too big" do
      assert {:invalid_uuid, :domain, :length} == catch_throw(HUUID.create("fff"))
    end

    test "domain is not hex" do
      assert {:invalid_uuid, :domain, :hex} == catch_throw(HUUID.create("wo"))
    end

    test "meta1 is not hex" do
      assert {:invalid_uuid, :meta1, :hex} == catch_throw(HUUID.create("ff", meta1: "wow"))
    end

    test "meta2 is not hex" do
      assert {:invalid_uuid, :meta2, :hex} == catch_throw(HUUID.create("ff", meta2: "wow"))
    end
  end

  describe "header/2" do
    test "header without mea" do
      assert "ff" == HUUID.header("ff")
    end

    test "header with meta1" do
      assert "ff1" == HUUID.header("ff", meta1: "1")
    end

    test "header with meta2" do
      assert "ff2" == HUUID.header("ff", meta2: "2")
    end

    test "header with both metas" do
      assert "ff12" == HUUID.header("ff", meta1: "1", meta2: "2")
    end

    test "header with variable length metas" do
      assert "ff123321" == HUUID.header("ff", meta1: "123", meta2: "321")
    end

    test "domain length is too small" do
      assert {:invalid_uuid, :domain, :length} == catch_throw(HUUID.header(""))
      assert {:invalid_uuid, :domain, :length} == catch_throw(HUUID.header("a"))
    end

    test "domain length is too big" do
      assert {:invalid_uuid, :domain, :length} == catch_throw(HUUID.header("fff"))
    end

    test "domain is not hex" do
      assert {:invalid_uuid, :domain, :hex} == catch_throw(HUUID.header("wo"))
    end

    test "meta1 is not hex" do
      assert {:invalid_uuid, :meta1, :hex} == catch_throw(HUUID.header("ff", meta1: "wow"))
    end

    test "meta2 is not hex" do
      assert {:invalid_uuid, :meta2, :hex} == catch_throw(HUUID.header("ff", meta2: "wow"))
    end
  end

  describe "generate/0" do
    test "uuid length" do
      uuid = HUUID.generate()
      assert String.length(uuid) == 36
    end
  end

  describe "merge/2" do
    test "correct merge" do
      str = HUUID.merge("ff", "abcd")
      assert "ffcd" = str
    end
  end
end

defmodule HELL.FormatTest do
  use ExUnit.Case

  alias HELL.UUID.Format, as: HUFormat

  describe "validate/1" do
    test "valid domain" do
      validation = HUFormat.validate(%{domain: "ff"})
      assert validation.valid?
    end

    test "valid domain and meta1" do
      validation = HUFormat.validate(%{domain: "ff", meta1: "aa"})
      assert validation.valid?
    end

    test "valid domain and meta2" do
      validation = HUFormat.validate(%{domain: "ff", meta2: "bb"})
      assert validation.valid?
    end

    test "valid domain and both metas" do
      validation = HUFormat.validate(%{domain: "ff", meta1: "aa", meta2: "bb"})
      assert validation.valid?
    end

    test "domain length too big" do
      validation = HUFormat.validate(%{domain: "fff"})
      assert not validation.valid?
      assert :max_length = validation.errors
    end

    test "domain length too small" do
      validation = HUFormat.validate(%{domain: ""})
      assert not validation.valid?
      assert :min_length = validation.errors
    end

    test "domain is not hex" do
      validation = HUFormat.validate(%{domain: "Wo"})
      assert not validation.valid?
      assert {:invalid_hex, :domain} = validation.errors
    end

    test "meta1 is not hex" do
      validation = HUFormat.validate(%{domain: "ff", meta1: "wo"})
      assert not validation.valid?
      assert {:invalid_hex, :meta1} = validation.errors
    end

    test "meta2 is not hex" do
      validation = HUFormat.validate(%{domain: "ff", meta2: "wo"})
      assert not validation.valid?
      assert {:invalid_hex, :meta2} = validation.errors
    end
  end

  describe "join/1" do
    test "valid domain join" do
      validation = HUFormat.validate(%{domain: "ff"}) |> HUFormat.join!()
      assert validation == "ff"
    end

    test "valid domain and meta1 join" do
      validation = HUFormat.validate(%{domain: "ff", meta1: "aa"}) |> HUFormat.join!()
      assert validation == "ffaa"
    end

    test "valid domain and meta2 join" do
      validation = HUFormat.validate(%{domain: "ff", meta2: "bb"}) |> HUFormat.join!()
      assert validation == "ffbb"
    end

    test "valid domain and both metas join" do
      validation = HUFormat.validate(%{domain: "ff", meta1: "aa", meta2: "bb"}) |> HUFormat.join!()
      assert validation == "ffaabb"
    end

    test "throws when domain length is too small" do
      validation1 = HUFormat.validate(%{"domain": ""})
      validation2 = HUFormat.validate(%{"domain": "a"})
      assert {:uuid_format_error, :min_length} == catch_throw(HUFormat.join!(validation1))
      assert {:uuid_format_error, :min_length} == catch_throw(HUFormat.join!(validation2))
    end

    test "throws when domain length is too big" do
      validation = HUFormat.validate(%{"domain": "fff"})
      assert {:uuid_format_error, :max_length} == catch_throw(HUFormat.join!(validation))
    end

    test "throws when domain is not hex" do
      validation = HUFormat.validate(%{"domain": "wo"})
      assert {:uuid_format_error, {:invalid_hex, :domain}} == catch_throw(HUFormat.join!(validation))
    end

    test "throws when meta1 is not hex" do
      validation = HUFormat.validate(%{"domain": "ff", meta1: "wo"})
      assert {:uuid_format_error, {:invalid_hex, :meta1}} == catch_throw(HUFormat.join!(validation))
    end

    test "throws when meta2 is not hex" do
      validation = HUFormat.validate(%{"domain": "ff", meta2: "wo"})
      assert {:uuid_format_error, {:invalid_hex, :meta2}} == catch_throw(HUFormat.join!(validation))
    end
  end
end

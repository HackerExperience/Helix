defmodule HELL.IPTest do
  use ExUnit.Case

  alias HELL.IP, as: HIP

  describe "create/2" do
    test "valid header" do
      assert {:ok, "abcd:0000:" <> _} = HIP.create("ab", "cd")
      assert {:ok, "abcd:a100:" <> _} = HIP.create("ab", "cd", meta1: "a1")
      assert {:ok, "abcd:00b2:" <> _} = HIP.create("ab", "cd", meta2: "b2")
      assert {:ok, "abcd:a1b2:" <> _} = HIP.create("ab", "cd", meta1: "a1", meta2: "b2")
    end

    test "valid IPv6" do
      {:ok, a} = HIP.create("12", "34")
      {:ok, b} = HIP.create("12", "34", meta1: "ab")
      {:ok, c} = HIP.create("12", "34", meta1: "ab", meta2: "cd")
      assert CIDR.is_cidr?(a)
      assert CIDR.is_cidr?(b)
      assert CIDR.is_cidr?(c)
    end

    test "invalid header is too small" do
      assert :error = HIP.create("0", "00")
      assert :error = HIP.create("00", "0")
      assert :error = HIP.create("00", "00", meta1: "0")
      assert :error = HIP.create("00", "00", meta2: "0")
    end

    test "invalid header is too lengthy" do
      assert :error = HIP.create("000", "00")
      assert :error = HIP.create("00", "000")
      assert :error = HIP.create("00", "00", meta1: "000")
      assert :error = HIP.create("00", "00", meta2: "000")
    end

    test "invalid header characters" do
      assert :error = HIP.create("gh", "00")
      assert :error = HIP.create("00", "gh")
      assert :error = HIP.create("00", "00", meta1: "gh")
      assert :error = HIP.create("00", "00", meta2: "gh")
    end
  end

  describe "create!/2" do
    test "success" do
      assert "abcd" <> _ = HIP.create!("ab", "cd")
    end

    test "failure" do
      assert_raise ArgumentError, fn ->
        HIP.create!("gh", "00")
      end
      assert_raise ArgumentError, fn ->
        HIP.create!("000", "00")
      end
      assert_raise ArgumentError, fn ->
        HIP.create!("0", "00")
      end
    end
  end

  describe "debug/1" do
    test "parsing valid information" do
      dom = "ab"
      obj = "cd"
      m1  = "12"
      m2  = "34"

      {:ok, ip} = HIP.create(dom, obj, meta1: m1, meta2: m2)
      assert %{domain: ^dom, object: ^obj, meta1: ^m1, meta2: ^m2} = HIP.debug(ip)
    end

    test "parsing invalid information" do
      assert_raise MatchError, fn ->
        HIP.debug("")
      end
    end
  end
end
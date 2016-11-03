defmodule HELL.IPTest do
  use ExUnit.Case

  import HELL.TestHelper.IP
  alias HELL.IP, as: HIP

  describe "generate/1" do
    test "success" do
      assert "3456:" <> _ = HELL.IPv6.generate([0x3456])
      assert "ef01:3456:" <> _ = HELL.IPv6.generate([0xef01, 0x3456])
      assert "abcd:ef01:3456:" <> _ = HELL.IPv6.generate([0xabcd, 0xef01, 0x3456])
      assert "abcd:ef:3:" <> _ = HELL.IPv6.generate([0xabcd, 0xef, 0x3])
    end

    test "validate" do
      ip = HELL.IPv6.generate([0xabcd, 0xef, 0x3])
      assert valid_ipv6?(ip)
    end

    test "error" do
      assert_raise ArgumentError, fn ->
        HELL.IPv6.generate([0xfffff])
      end
    end
  end
end
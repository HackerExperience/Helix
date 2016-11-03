defmodule HELL.IPv6Test do
  use ExUnit.Case

  import HELL.TestHelper.IP
  alias HELL.IP, as: HIP

  describe "IPv6 generation via generate/1" do
    test "it includes the header" do
      assert "3456:" <> _ = HELL.IPv6.generate([0x3456])
      assert "ef01:3456:" <> _ = HELL.IPv6.generate([0xef01, 0x3456])
      assert "abcd:ef01:3456:" <> _ = HELL.IPv6.generate([0xabcd, 0xef01, 0x3456])
      assert "abcd:ef:3:" <> _ = HELL.IPv6.generate([0xabcd, 0xef, 0x3])
      assert "abcd:0:abcd:" <> _ = HELL.IPv6.generate([0xabcd, 0x0, 0xabcd])
    end

    test "it generates a valid ipv6" do
      ip = HELL.IPv6.generate([0xabcd, 0xef, 0x3])
      assert valid_ipv6?(ip)
    end

    test "it raises ArgumentError when range is exceeded" do
      assert_raise ArgumentError, fn ->
        HELL.IPv6.generate([0xfffff])
      end
    end
  end
end
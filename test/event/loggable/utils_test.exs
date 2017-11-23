defmodule Helix.Loggable.UtilsTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Loggable.Utils, as: LoggableUtils
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Network

  describe "censor_ip/1" do
    test "orwellian censorship" do
      ip1 = "[123.123.123.123]"
      re1 = "[123.123.1xx.xxx]"

      ip2 = "[123.123.12.123]"
      re2 = "[123.123.xx.xxx]"

      ip3 = "[123.123.12.12]"
      re3 = "[123.12x.xx.xx]"

      ip4 = "[123.123.12.1]"
      re4 = "[123.1xx.xx.x]"

      ip5 = "[123.123.1.1]"
      re5 = "[123.xxx.x.x]"

      ip6 = "[1.2.3.4]"
      re6 = "[x.x.x.x]"

      ip7 = "[Unknown]"
      re7 = "[Unknown]"

      cs1 = LoggableUtils.censor_ip(ip1)
      cs2 = LoggableUtils.censor_ip(ip2)
      cs3 = LoggableUtils.censor_ip(ip3)
      cs4 = LoggableUtils.censor_ip(ip4)
      cs5 = LoggableUtils.censor_ip(ip5)
      cs6 = LoggableUtils.censor_ip(ip6)
      cs7 = LoggableUtils.censor_ip(ip7)

      assert cs1 == re1
      assert cs2 == re2
      assert cs3 == re3
      assert cs4 == re4
      assert cs5 == re5
      assert cs6 == re6
      assert cs7 == re7
    end
  end

  describe "get_ip/2" do
    test "Returns `Unknow` if not found" do
      ip = LoggableUtils.get_ip(Server.ID.generate(), Network.ID.generate())
      assert ip == "Unknown"
    end
  end
end

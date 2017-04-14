defmodule Helix.Process.Service.Local.TOP.ManagerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.Service.Local.TOP.Manager

  test "returns the registered process when it exists" do
    Manager.register("a:b::c:d")

    assert {:ok, self()} == Manager.prepare_top("a:b::c:d")
    assert {:ok, self()} == Manager.prepare_top("a:b::c:d")
  end
end

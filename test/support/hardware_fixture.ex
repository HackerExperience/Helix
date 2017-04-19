defmodule Helix.Hardware.Fixture do
  alias Helix.Hardware.Factory

  def insert(:cpu) do
    Factory.insert(:cpu, clock: 120, cores: 1).component
  end

  def insert(:ram) do
    Factory.insert(:ram, ram_size: 120).component
  end

  def insert(:hdd) do
    Factory.insert(:hdd, hdd_size: 120).component
  end

  def insert(:nic) do
    Factory.insert(:nic).component
  end
end

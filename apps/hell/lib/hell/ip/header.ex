defmodule HELL.IPv6.Header do
  @moduledoc """
  Primary key generator for named modules, usually used with `Ecto` schemas.
  """

  @mappings %{
    # Account
    Helix.Account.Model.Account                    => [0x0000],

    # Server
    Helix.Server.Model.Server                      => [0x0002],

    # Hardware
    Helix.Hardware.Model.Component                 => [0x0003, 0x0001],
    Helix.Hardware.Model.Motherboard               => [0x0003, 0x0001, 0x0000],
    Helix.Hardware.Model.Component.HDD             => [0x0003, 0x0001, 0x0001],
    Helix.Hardware.Model.Component.CPU             => [0x0003, 0x0001, 0x0002],
    Helix.Hardware.Model.Component.RAM             => [0x0003, 0x0001, 0x0003],
    Helix.Hardware.Model.Component.NIC             => [0x0003, 0x0001, 0x0004],
    Helix.Hardware.Model.MotherboardSlot           => [0x0003, 0x0002],
    Helix.Hardware.Model.NetworkConnection         => [0x0003, 0x0003],

    # Sofware
    Helix.Software.Model.File                      => [0x0004, 0x0000],
    Helix.Software.Model.Storage                   => [0x0004, 0x0001],
    Helix.Software.Model.StorageDrive              => [0x0004, 0x0001, 0x0001],
    Helix.Software.Model.ModuleRole                => [0x0004, 0x0002],

    # Process
    Helix.Process.Model.Process                    => [0x0005, 0x0000],

    # NPC
    Helix.NPC.Model.NPC                            => [0x0006],

    # Clan
    Helix.Clan.Model.Clan                          => [0x0007],

    # Log
    Helix.Log.Model.Log                            => [0x0008, 0x0000],
    Helix.Log.Model.Revision                       => [0x0008, 0x0001]
  }

  @doc """
  Generates a PK for given module with a proper header, raises `RuntimeError`
  when no header is available for the module.
  """
  @spec pk_for(module) :: HELL.PK.t
  for {module, header} <- @mappings do
    def pk_for(unquote(module)),
      do: HELL.IPv6.generate(unquote(header))
  end
end
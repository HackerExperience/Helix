defmodule HELL.PK.Header do

  @mappings %{
    # Network
    # Note that network is the one to receive the 0:0:0 pk head so we can use
    # "::" as a constant value for the internet (ie: global all-players network)
    Helix.Network.Model.Network                     => [0x0000, 0x0000, 0x0000],

    # Account
    Helix.Account.Model.Account                     => [0x0001, 0x0000, 0x0000],

    # NPC
    Helix.NPC.Model.NPC                             => [0x0002, 0x0000, 0x0000],

    # Clan
    Helix.Clan.Model.Clan                           => [0x0003, 0x0000, 0x0000],

    # Server
    Helix.Server.Model.Server                       => [0x0010, 0x0000, 0x0000],

    # Hardware
    Helix.Hardware.Model.Component                  => [0xffff], # FIXME
    Helix.Hardware.Model.Motherboard                => [0x0011, 0x0001, 0x0000],
    Helix.Hardware.Model.Component.HDD              => [0x0011, 0x0001, 0x0001],
    Helix.Hardware.Model.Component.CPU              => [0x0011, 0x0001, 0x0002],
    Helix.Hardware.Model.Component.RAM              => [0x0011, 0x0001, 0x0003],
    Helix.Hardware.Model.Component.NIC              => [0x0011, 0x0001, 0x0004],
    Helix.Hardware.Model.MotherboardSlot            => [0x0011, 0x0002, 0x0000],
    Helix.Hardware.Model.NetworkConnection          => [0x0011, 0x0003, 0x0000],

    # Sofware
    Helix.Software.Model.File                       => [0x0020, 0x0000, 0x0000],
    Helix.Software.Model.Storage                    => [0x0020, 0x0001, 0x0000],
    Helix.Software.Model.StorageDrive               => [0x0020, 0x0001, 0x0001],
    Helix.Software.Model.ModuleRole                 => [0x0020, 0x0002, 0x0000],

    # Process
    Helix.Process.Model.Process                     => [0x0021, 0x0000, 0x0000],

    # Log
    Helix.Log.Model.Log                             => [0x0030, 0x0000, 0x0000],
    Helix.Log.Model.Revision                        => [0x0030, 0x0001, 0x0000]
  }

  @spec pk_for(module) :: HELL.PK.t
  @doc """
  Generates a PK for given module with a proper header, raises
  `FunctionClauseError` when no header is available for the module.
  """
  for {module, header} <- @mappings do
    def pk_for(unquote(module)),
      do: HELL.IPv6.generate(unquote(header))
  end
end

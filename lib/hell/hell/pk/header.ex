defmodule HELL.PK.Header do

  @mappings %{
    # Network
    # Note that network is the one to receive the 0:0:0 pk head so we can use
    # "::" as a constant value for the internet (ie: global all-players network)
    network_network:
      [0x0000, 0x0000, 0x0000],
    network_tunnel:
      [0x0000, 0x0001, 0x0000],
    network_connection:
      [0x0000, 0x0001, 0x0001],
    account_account:
      [0x0001, 0x0000, 0x0000],
    npc_npc:
      [0x0002, 0x0000, 0x0000],
    clan_clan:
      [0x0003, 0x0000, 0x0000],
    server_server:
      [0x0010, 0x0000, 0x0000],
    hardware_component:
      [0xffff], # FIXME
    hardware_motherboard:
      [0x0011, 0x0001, 0x0001],
    hardware_component_hdd:
      [0x0011, 0x0001, 0x0002],
    hardware_component_cpu:
      [0x0011, 0x0001, 0x0003],
    hardware_component_ram:
      [0x0011, 0x0001, 0x0004],
    hardware_component_nic:
      [0x0011, 0x0001, 0x0005],
    hardware_motherboard_slot:
      [0x0011, 0x0002, 0x0000],
    hardware_network_connection:
      [0x0011, 0x0003, 0x0000],
    software_file:
      [0x0020, 0x0000, 0x0000],
    software_storage:
      [0x0020, 0x0001, 0x0000],
    process_process:
      [0x0021, 0x0000, 0x0000],
    log_log:
      [0x0030, 0x0000, 0x0000],
    log_revision:
      [0x0030, 0x0001, 0x0000]
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

defmodule Helix.ID.Domain do
  @moduledoc """
  Network:
    networks:
      internet:         00
      story:            10
      mission:          20
      lan:              30
      reserved_until:   70
    tunnel:             80
    bounce:             A0
    connection:
      ssh:              01
      ftp:              11
      public_ftp:       21
      bank_login:       31
      wire_transfer:    41
      virus_collect:    51
      cracker_bf:       61
      reserved_until:   F1
      reserved_until:   F2
  Process:
    process:
      file_dl:          03
      file_up:          13
      crc_bruteforce:   23
      crc_overflow:     33
      install_virus:    43
      virus_collect:    53
      wire_transfer:    63
      bank_reveal_pass: 73
      log_forge:        83
      reserved_until:   F3
      reserved_until:   F4

  Server:
    server:
      desktop:          05
      mobile:           15
      npc:              25
      desktop_story:    35
      npc_story:        45
      reserved_until:   75
    component:
      cpu:              85
      ram:              95
      hdd:              A5
      nic:              B5
      mobo:             C5
      reserved_until:   F5
      
  Software:
    file:
      crc:              06
      fwl:              16
      text:             26
      exp:              36
      hasher:           46
      log_f:            56
      log_r:            66
      enc:              76
      dec:              86
      anymap:           96
      virus_spy:        A6
      virus_<reserved>: F6
      crypto_key:       07
      reserved_until:   F7
    storage:            08
    reserved_until:     78

  <unused>:             88
  <unused>:             F8

  Log:
    log:                09
    revision:           19
    reserved_until:     79

  <unused>:             89
  <unused>:             F9

  Entity:
    entity:
      account:          0A
      npc:              1A
      clan:             2A
      reserved_until:   7A

  Account:
    session:            8A
    reserved_until:     FA

  Universe:
    Bank:
      transfer:         0B
      reserved_until:   7B

  <unused>:             8B
  <unused>:             FE

  Notification:
    account:            0F
    server:             1F
    clan:               2F
    chat:               3F
    reserved_until:     5F

  <unused>:             6F
  <unused>:             FF
  """

  alias Helix.Network.Model.Connection
  alias Helix.Notification.Model.Notification
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Software

  @type domain ::
    {:network, :story | :mission | :lan}
    | :tunnel
    | :bounce
    | {:connection, Connection.type}
    | {:process, Process.type}
    | {:server, Server.Type.type}
    | {:component, Component.type}
    | {:file, Software.type}
    | {:software, :storage}
    | :log
    | {:log, :revision}
    | {:entity, :account | :npc | :clan}
    | {:bank, :transfer}
    | {:notification, Notification.class}
    | :account
    | :npc
    | :clan

  @domain_table [
    {{:network, :story}, 0x10},
    {{:network, :mission}, 0x20},
    {{:network, :lan}, 0x30},
    {:tunnel, 0x80},
    {:bounce, 0xA0},
    {{:connection, :ssh}, 0x01},
    {{:connection, :ftp}, 0x11},
    {{:connection, :public_ftp}, 0x21},
    {{:connection, :bank_login}, 0x31},
    {{:connection, :wire_transfer}, 0x41},
    {{:connection, :virus_collect}, 0x51},
    {{:connection, :cracker_bruteforce}, 0x61},
    {{:process, :fake_default_process}, 0x03},
    {{:process, :file_download}, 0x03},
    {{:process, :file_upload}, 0x13},
    {{:process, :cracker_bruteforce}, 0x23},
    {{:process, :cracker_overflow}, 0x33},
    {{:process, :install_virus}, 0x43},
    {{:process, :virus_collect}, 0x53},
    {{:process, :wire_transfer}, 0x63},
    {{:process, :bank_reveal_password}, 0x73},
    {{:process, :log_forge_create}, 0x83},
    {{:process, :log_forge_edit}, 0x83},
    {{:server, :desktop}, 0x05},
    {{:server, :mobile}, 0x15},
    {{:server, :npc}, 0x25},
    {{:server, :desktop_story}, 0x35},
    {{:server, :npc_story}, 0x45},
    {{:component, :cpu}, 0x85},
    {{:component, :ram}, 0x95},
    {{:component, :hdd}, 0xA5},
    {{:component, :nic}, 0xB5},
    {{:component, :mobo}, 0xC5},
    {{:file, :cracker}, 0x06},
    {{:file, :firewall}, 0x16},
    {{:file, :text}, 0x26},
    {{:file, :exploit}, 0x36},
    {{:file, :hasher}, 0x46},
    {{:file, :log_forger}, 0x56},
    {{:file, :log_recover}, 0x66},
    {{:file, :decryptor}, 0x76},
    {{:file, :encryptor}, 0x86},
    {{:file, :anymap}, 0x96},
    {{:file, :virus_spyware}, 0xA6},
    {{:file, :crypto_key}, 0x07},
    {{:software, :storage}, 0x08},
    {:log, 0x09},
    {{:log, :revision}, 0x19},
    {{:entity, :account}, 0x0A},
    {{:entity, :npc}, 0x1A},
    {{:entity, :clan}, 0x2A},
    {{:bank, :transfer}, 0x0B},
    {{:notification, :account}, 0x0F},
    {{:notification, :server}, 0x1F},
    {{:notification, :clan}, 0x2F},
    {{:notification, :chat}, 0x3F}
  ]

  @alias_table [
    {:account, {:entity, :account}},
    {:npc, {:entity, :npc}},
    {:clan, {:entity, :clan}}
  ]

  @spec get_domain(domain) ::
    binary

  for {domain, dec} <- @domain_table do

    bin = dec |> Integer.to_string(2) |> String.pad_leading(8, "0")

    @doc false
    def get_domain(unquote(domain)),
      do: unquote(bin)

  end

  for {domain, delegate_to} <- @alias_table do

    @doc false
    def get_domain(unquote(domain)),
      do: get_domain(unquote(delegate_to))

  end
end

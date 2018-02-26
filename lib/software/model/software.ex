defmodule Helix.Software.Model.Software do

  use Helix.Software

  @type t ::
    %{
      type: type,
      extension: extension,
      modules: [module_name]
    }

  @type type ::
    :cracker
    | :firewall
    | :text
    | :exploit
    | :hasher
    | :log_forger
    | :log_recover
    | :encryptor
    | :decryptor
    | :anymap
    | :crypto_key
    | :virus_spyware

  @type virus :: :virus_spyware

  @type module_name ::
    cracker_module
    | firewall_module
    | exploit_module
    | log_forger_module
    | log_recover_module
    | encryptor_module
    | decryptor_module
    | anymap_module
    | spyware_module

  @type cracker_module :: :bruteforce | :overflow
  @type firewall_module :: :fwl_active | :fwl_passive
  @type exploit_module :: :ftp | :ssh
  @type hasher_module :: :password
  @type log_forger_module :: :log_create | :log_edit
  @type log_recover_module :: :log_recover
  @type encryptor_module :: :enc_file | :enc_log | :enc_conn | :enc_process
  @type decryptor_module :: :dec_file | :dec_log | :dec_conn | :dec_process
  @type anymap_module :: :map_geo | :map_net
  @type spyware_module :: :vir_spyware

  @type extension ::
    :crc
    | :fwl
    | :txt
    | :exp
    | :hash
    | :logf
    | :logr
    | :enc
    | :dec
    | :map
    | :key
    | :spy

  software \
    type: :cracker,
    extension: :crc,
    modules: [:bruteforce, :overflow]

  software \
    type: :firewall,
    extension: :fwl,
    modules: [:fwl_active, :fwl_passive]

  software \
    type: :text,
    extension: :txt

  software \
    type: :exploit,
    extension: :exp,
    modules: [:ftp, :ssh]

  software \
    type: :hasher,
    extension: :hash,
    modules: [:password]

  software \
    type: :log_forger,
    extension: :logf,
    modules: [:log_create, :log_edit]

  software \
    type: :log_recover,
    extension: :logr,
    modules: [:log_recover]

  software \
    type: :encryptor,
    extension: :enc,
    modules: [:enc_file, :enc_log, :enc_conn, :enc_process]

  software \
    type: :decryptor,
    extension: :dec,
    modules: [:dec_file, :dec_log, :dec_conn, :dec_process]

  software \
    type: :anymap,
    extension: :map,
    modules: [:map_geo, :map_net]

  software \
    type: :crypto_key,
    extension: :key

  software \
    type: :virus_spyware,
    extension: :spy,
    modules: [:vir_spyware]
end

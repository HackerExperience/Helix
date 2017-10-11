defmodule Helix.Software.Model.Software do

  use Helix.Software

  software \
    type: :cracker,
    extension: "crc",
    modules: [:bruteforce, :overflow]

  software \
    type: :firewall,
    extension: "fwl",
    modules: [:fwl_active, :fwl_passive]

  software \
    type: :text,
    extension: "txt"

  software \
    type: :exploit,
    extension: "exp",
    modules: [:ftp, :ssh]

  software \
    type: :hasher,
    extension: "hash",
    modules: [:password]

  software \
    type: :log_forger,
    extension: "logf",
    modules: [:log_create, :log_edit]

  software \
    type: :log_recover,
    extension: "logr",
    modules: [:log_recover]

  software \
    type: :encryptor,
    extension: "enc",
    modules: [:enc_file, :enc_log, :enc_connection, :enc_process]

  software \
    type: :decryptor,
    extension: "dec",
    modules: [:dec_file, :dec_log, :dec_connection, :dec_process]

  software \
    type: :anymap,
    extension: "map",
    modules: [:map_geo, :map_net]

  software \
    type: :crypto_key,
    extension: "key"
end

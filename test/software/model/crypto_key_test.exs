# defmodule Helix.Software.Model.CryptoKeyTest do

#   use ExUnit.Case, async: true

#   alias Helix.Server.Model.Server
#   alias Helix.Software.Model.CryptoKey
#   alias Helix.Software.Model.File
#   alias Helix.Software.Model.Storage

#   @moduletag :unit

#   describe "create/3" do
#est "when provided with a storage, a server_id and a target file, succeeds" do
#       file = %File{}
#       storage = %Storage{}
#       server_id = Server.ID.generate()

#       changeset = CryptoKey.create(storage, server_id, file)

#       assert changeset.valid?
#     end
#   end
# end

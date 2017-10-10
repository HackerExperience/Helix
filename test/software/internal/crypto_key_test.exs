# defmodule Helix.Software.Internal.CryptoKeyTest do

#   use Helix.Test.Case.Integration

#   alias Helix.Server.Model.Server
#   alias Helix.Software.Internal.CryptoKey, as: CryptoKeyInternal
#   alias Helix.Software.Internal.File, as: FileInternal
#   alias Helix.Software.Model.CryptoKey.InvalidatedEvent

#   alias Helix.Test.Software.Factory
#   alias Helix.Test.Software.Setup, as: SoftwareSetup

#   describe "create/3" do
#     test "will create a file for the key on storage" do
#       {storage, _} = SoftwareSetup.storage()

#       file_opts = [storage_id: storage.storage_id, crypto_version: 1]
#       gen_files = SoftwareSetup.random_files!(total: 3, file_opts: file_opts)

#       server_id = Server.ID.generate()

#       Enum.each(gen_files, fn file ->
#         CryptoKeyInternal.create(storage, server_id, file)
#       end)

#       files = FileInternal.get_files_on_storage(storage)

#       assert 3 == Enum.count(files)
#       assert Enum.all?(files, &(&1.software_type == :crypto_key))
#     end
#   end

#   describe "get_files_targeted_on_storage/2" do
#     test "returns files for which the origin storage has a key" do
#       origin_storage = Factory.insert(:storage, %{files: []})
#       target_storage = Factory.insert(:storage, %{files: []})
#       Factory.insert_list(5, :file, %{storage: target_storage})

#       encrypted_files = Factory.insert_list(
#         5,
#         :file,
#         %{storage: target_storage, crypto_version: 1})

#       server_id = Server.ID.generate()
#       create_key = &CryptoKeyInternal.create(origin_storage, server_id, &1)
#       Enum.each(encrypted_files, create_key)

#       files = CryptoKeyInternal.get_files_targeted_on_storage(
#         origin_storage,
#         target_storage)

#       assert 5 == Enum.count(files)
#       assert Enum.all?(files, &(not is_nil(&1)))
#     end

#     test "returns no unencrypted files" do
#       origin_storage = Factory.insert(:storage, %{files: []})
#       target_storage = Factory.insert(:storage, %{files: []})
#       Factory.insert_list(5, :file, %{storage: target_storage})

#       files = CryptoKeyInternal.get_files_targeted_on_storage(
#         origin_storage,
#         target_storage)

#       assert Enum.empty?(files)
#     end
#   end

#   describe "invalidate_keys_for_file/1" do
#     test "will unlink any key that is bound to target file" do
#       storages = Factory.insert_list(3, :storage, %{files: []})
#       file = Factory.insert(:file, %{crypto_version: 1})

#       server_id = Server.ID.generate()
#       create_key_for_file = &CryptoKeyInternal.create(&1, server_id, file)
#       Enum.each(storages, create_key_for_file)

#       keys_before = Enum.flat_map(
#         storages,
#         &CryptoKeyInternal.get_on_storage/1)

#       CryptoKeyInternal.invalidate_keys_for_file(file)

#       keys_after = Enum.flat_map(
#         storages,
#         &CryptoKeyInternal.get_on_storage/1)

#       refute Enum.any?(keys_before, &is_nil(&1.target_file_id))
#       assert Enum.all?(keys_after, &is_nil(&1.target_file_id))
#     end

#     test "returns an event for each invalidated key" do
#       storages = Factory.insert_list(3, :storage, %{files: []})
#       file = Factory.insert(:file, %{crypto_version: 1})

#       server_id = Server.ID.generate()
#       create_key_for_file = &CryptoKeyInternal.create(&1, server_id, file)
#       Enum.each(storages, create_key_for_file)

#       events = CryptoKeyInternal.invalidate_keys_for_file(file)

#       assert 3 == Enum.count(events)
#       assert Enum.all?(events, &match?(%InvalidatedEvent{}, &1))
#     end
#   end
# end

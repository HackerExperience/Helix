defmodule Helix.IDTest do

  use ExUnit.Case, async: true

  alias Helix.ID

  describe "generate/2" do
    test "generates IDs with correct time, heritage and domain hashes" do
      # Scenario: we'll generate three IDs that should cover all cases regarding
      # heritage. First, we'll create an Entity ID. Entity IDs have no parents
      # nor grandparents. Then, we'll create a Server ID that belongs to this
      # Entity, so the Entity ID should be used as parent to the Server ID.
      # Finally, we'll create a Process ID that belongs to that Server (parent)
      # and to that Entity (grandparent).
      # Note that this hierarchy is not necessarily the one used in production,
      # that's just a scenario created for this test case.

      entity_id = ID.generate(%{}, {:entity, :account})
      entity_id_bin = ID.Utils.id_to_bin(entity_id)
      entity_id_hex = ID.Utils.bin_to_hex(entity_id_bin, 32)
      parsed_entity_id = ID.Utils.parse(entity_id)

      # `{:entity, :account}` hashes must end with `0A`
      assert String.ends_with?(entity_id_hex, "0A")

      # Now the Server ID will be generated, with `entity_id` as parent.
      # Since this is the only parent, all 54-bits of heritage on Server ID will
      # be used to hash `entity_id`. From which 19 bits will hash Entity ID's
      # grandparent, 19 bits will hash the parent, and 16 bits will hash the
      # Entity ID object
      expected_entity_gp_hash = hash(parsed_entity_id.grandparent.dec, 19)
      expected_entity_p_hash = hash(parsed_entity_id.parent.dec, 19)
      expected_entity_o_hash = hash(parsed_entity_id.object.dec, 16)

      expected_server_heritage_hash =
        expected_entity_gp_hash <>
        expected_entity_p_hash <>
        expected_entity_o_hash

      server_heritage = %{parent: entity_id}
      server_id = ID.generate(server_heritage, {:server, :desktop})
      server_id_bin = ID.Utils.id_to_bin(server_id)
      server_id_hex = ID.Utils.bin_to_hex(server_id_bin, 32)
      parsed_server_id = ID.Utils.parse(server_id)

      # `{:server, :desktop}` hashes must end with `05`
      assert String.ends_with?(server_id_hex, "05")

      # Server ID correctly hashed heritage information
      assert String.starts_with?(server_id_bin, expected_server_heritage_hash)

      # `server_id` ts hash is equal or at most 1 second higher than entity ts
      assert_in_delta \
        parsed_entity_id.timestamp.dec, parsed_server_id.timestamp.dec, 1

      # Now we'll generate the Process ID, with information from both the Server
      # (parent) and the Entity (grandparent).
      # As a result, 24 bits will be reserved for the grandparent, and 30 bits
      # for the parent.

      expected_entity_gp_hash = hash(parsed_entity_id.grandparent.dec, 10)
      expected_entity_p_hash = hash(parsed_entity_id.parent.dec, 10)
      expected_entity_o_hash = hash(parsed_entity_id.object.dec, 4)

      # 24 bits for entity ID...
      expected_entity_hash =
        expected_entity_gp_hash <>
        expected_entity_p_hash <>
        expected_entity_o_hash

      expected_server_gp_hash = hash(parsed_server_id.grandparent.dec, 11)
      expected_server_p_hash = hash(parsed_server_id.parent.dec, 11)
      expected_server_o_hash = hash(parsed_server_id.object.dec, 8)

      # 30 bits for server ID...
      expected_server_hash =
        expected_server_gp_hash <>
        expected_server_p_hash <>
        expected_server_o_hash

      # Totaling 54 bits of heritage
      expected_process_heritage_hash =
        expected_entity_hash <> expected_server_hash

      process_heritage = %{grandparent: entity_id, parent: server_id}

      process_id = ID.generate(process_heritage, {:process, :file_download})
      process_id_bin = ID.Utils.id_to_bin(process_id)
      process_id_hex = ID.Utils.bin_to_hex(process_id_bin, 32)
      parsed_process_id = ID.Utils.parse(process_id)

      # `{:process, :file_download}` hashes must end with `03`
      assert String.ends_with?(process_id_hex, "03")

      # Process ID correctly hashed heritage information
      assert String.starts_with?(process_id_bin, expected_process_heritage_hash)

      # `process_id` ts hash is equal or at most 1 second higher than server ts
      assert_in_delta \
        parsed_server_id.timestamp.dec, parsed_process_id.timestamp.dec, 1
    end

    test "heritage increases spatial locality" do
      entity_id = ID.generate(%{}, {:entity, :account})

      server_heritage = %{parent: entity_id}
      server_domain = {:server, :desktop}
      server1_id = ID.generate(server_heritage, server_domain)
      server2_id = ID.generate(server_heritage, server_domain)

      server1_id_bin = ID.Utils.id_to_bin(server1_id)
      server2_id_bin = ID.Utils.id_to_bin(server2_id)

      process_domain = {:process, :file_upload}
      process_heritage_s1 = %{grandparent: entity_id, parent: server1_id}
      proc1_s1_id = ID.generate(process_heritage_s1, process_domain)
      proc2_s1_id = ID.generate(process_heritage_s1, process_domain)
      proc3_s1_id = ID.generate(process_heritage_s1, process_domain)

      process_heritage_s2 = %{grandparent: entity_id, parent: server2_id}
      proc1_s2_id = ID.generate(process_heritage_s2, process_domain)
      proc2_s2_id = ID.generate(process_heritage_s2, process_domain)
      proc3_s2_id = ID.generate(process_heritage_s2, process_domain)

      proc1_s1_id_bin = ID.Utils.id_to_bin(proc1_s1_id)
      proc2_s1_id_bin = ID.Utils.id_to_bin(proc2_s1_id)
      proc3_s1_id_bin = ID.Utils.id_to_bin(proc3_s1_id)
      proc1_s2_id_bin = ID.Utils.id_to_bin(proc1_s2_id)
      proc2_s2_id_bin = ID.Utils.id_to_bin(proc2_s2_id)
      proc3_s2_id_bin = ID.Utils.id_to_bin(proc3_s2_id)

      # Servers heritage are the same
      assert slice(server1_id_bin, 0..53) == slice(server2_id_bin, 0..53)

      # Processes belonging to the same server have the same heritage
      assert slice(proc1_s1_id_bin, 0..53) == slice(proc2_s1_id_bin, 0..53)
      assert slice(proc2_s1_id_bin, 0..53) == slice(proc3_s1_id_bin, 0..53)

      assert slice(proc1_s2_id_bin, 0..53) == slice(proc2_s2_id_bin, 0..53)
      assert slice(proc2_s2_id_bin, 0..53) == slice(proc3_s2_id_bin, 0..53)

      # Process from same entity on different servers have the same grandparent
      assert slice(proc1_s1_id_bin, 0..23) == slice(proc1_s2_id_bin, 0..23)
      assert slice(proc2_s1_id_bin, 0..23) == slice(proc2_s2_id_bin, 0..23)
      assert slice(proc3_s1_id_bin, 0..23) == slice(proc3_s2_id_bin, 0..23)

      # But different `parent` hashes
      refute slice(proc1_s1_id_bin, 24..53) == slice(proc1_s2_id_bin, 24..53)
      refute slice(proc2_s1_id_bin, 24..53) == slice(proc2_s2_id_bin, 24..53)
      refute slice(proc3_s1_id_bin, 24..53) == slice(proc3_s2_id_bin, 24..53)
    end

    test "benchmark" do
      # Generate 1000 IDs without parent and gp
      time_start = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      1..1_000
      |> Enum.each(fn _ ->
        ID.generate(%{}, {:entity, :account})
      end)
      time_end = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      time_without_heritage = time_end - time_start

      parent_id = ID.generate(%{}, {:entity, :account})
      heritage = %{parent: parent_id}

      # Generate 1000 IDs with parent (no GP)
      time_start = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      1..1_000
      |> Enum.each(fn _ ->
        ID.generate(heritage, {:server, :desktop})
      end)
      time_end = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      time_with_parent = time_end - time_start

      grandparent_id = ID.generate(%{}, {:server, :desktop})
      heritage = %{parent: parent_id, grandparent: grandparent_id}

      # Generate 1000 IDs with both parent and GP
      time_start = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      1..1_000
      |> Enum.each(fn _ ->
        ID.generate(heritage, {:process, :file_download})
      end)
      time_end = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      time_with_grandparent = time_end - time_start

      IO.inspect(time_without_heritage)
      IO.inspect(time_with_parent)
      IO.inspect(time_with_grandparent)

      # Below time (in milliseconds) required to generate 1000 IDs. Seems OK.
      # Note that these values were tuned while stressing the system (with cross
      # compilations and dialyzer verifications). Under normal load, it should
      # take half of the time listed below.
      assert time_without_heritage <= 250
      assert time_with_parent <= 350
      assert time_with_grandparent <= 450
    end

    defp slice(str, range),
      do: String.slice(str, range)

    defp hash(decimal, size) do
      decimal
      |> rem(ID.Utils.modulo_for(size))
      |> Integer.to_string(2)
      |> String.pad_leading(size, "0")
    end
  end
end

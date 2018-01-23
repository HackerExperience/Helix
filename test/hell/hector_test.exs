defmodule HectorTest do

  use Helix.Test.Case.Integration

  alias Hector
  alias Helix.Network.Repo, as: NetworkRepo
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo, as: SoftwareRepo

  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "get/3" do

    test "without loader (1)" do
      {file, _} = SoftwareSetup.file()

      sql = "SELECT * FROM files WHERE file_id = ##1::file_id"

      {:ok, query} = Hector.query(sql, [file.file_id])

      assert {:ok, [entry]} = Hector.get(SoftwareRepo, query, load: false)

      # Returned a map
      assert is_map(entry)

      # It's not a struct!
      refute Map.has_key?(entry, :__struct__)

      assert entry.full_path == file.full_path
      assert entry.path == file.path

      # It's a dumb mapper, so the IDs were not cast to Helix.ID. But they are
      # correct.
      assert to_string(entry.file_id) == to_string(file.file_id)
      assert to_string(entry.storage_id) == to_string(file.storage_id)
    end

    test "without a loader (2)" do
      {sql, {gateway1, expected1}, {gateway2, expected2}} =
        context_for_tunnel_query()

      {:ok, q1} = Hector.query(sql, [gateway1])
      {:ok, q2} = Hector.query(sql, [gateway2])

      assert {:ok, result1} = Hector.get(NetworkRepo, q1, load: false)
      assert {:ok, result2} = Hector.get(NetworkRepo, q2, load: false)

      # I ran out of line-width space...
      str = &to_string/1

      result1
      |> Enum.sort()
      |> Enum.zip(expected1)
      |> Enum.each(fn {result, expected} ->
        assert str.(result.destination_id) == str.(expected.destination_id)
        assert str.(result.gateway_id) == str.(expected.gateway_id)
        assert result.bounces == expected.bounce_id
      end)

      result2
      |> Enum.sort()
      |> Enum.zip(expected2)
      |> Enum.each(fn {result, expected} ->
        assert str.(result.destination_id) == str.(expected.destination_id)
        assert str.(result.gateway_id) == str.(expected.gateway_id)

        result.bounces
        |> Enum.sort()
        |> Enum.zip(Enum.sort(expected.bounce_id))
        |> Enum.each(fn {r_bounce, e_bounce} ->
          assert str.(r_bounce) == str.(e_bounce)
        end)
      end)
    end

    test "with simple loader (1)" do
      {file, _} = SoftwareSetup.file()

      sql = "SELECT * FROM files WHERE file_id = ##1::file_id"

      {:ok, query} = Hector.query(sql, [file.file_id])

      assert {:ok, [entry]} = Hector.get(SoftwareRepo, query, load: File)

      # File has been loaded successfully...
      assert entry.file_id == file.file_id
      assert entry.storage_id == file.storage_id
      assert entry.path == file.path
      assert entry.inserted_at == file.inserted_at

      # File.Module association was not loaded
      refute entry.modules == file.modules
    end

    test "with simple loader (2)" do
      {sql, {gateway1, _}, _} = context_for_tunnel_query()

      {:ok, q1} = Hector.query(sql, [gateway1])

      alias Helix.Network.Model.Tunnel
      assert {:ok, [entry, _]} = Hector.get(NetworkRepo, q1, load: Tunnel)

      # It loaded the fields it could find...
      assert %Server.ID{} = entry.destination_id
      assert %Server.ID{} = entry.gateway_id

      # And ignored what was not returned
      refute entry.tunnel_id
      refute entry.network_id
      refute entry.bounce_id
    end

    test "with custom loader (1)" do
      {file, _} = SoftwareSetup.file()

      sql = "SELECT * FROM files WHERE file_id = ##1::file_id"

      {:ok, query} = Hector.query(sql, [file.file_id])

      loader = fn repo, {columns, rows} ->
        rows
        |> Enum.map(fn row ->
          file = apply(repo, :load, [File, {columns, row}])

          repo
          |> apply(:preload, [file, :modules])
          |> FileInternal.format()
        end)
      end

      assert {:ok, [entry]} = Hector.get(SoftwareRepo, query, loader)

      # Now we have the returned entry identical to the generated file, because
      # we've preloaded the FileModules on our custom loader.
      assert entry == file
    end

    defp context_for_tunnel_query do
      sql = """
      SELECT DISTINCT t.gateway_id, t.destination_id, (
        SELECT ARRAY_REMOVE(ARRAY_AGG(source_id), t.gateway_id)
        FROM links
        WHERE tunnel_id = t.tunnel_id) as bounces
      FROM tunnels t
      INNER JOIN connections c
      ON t.tunnel_id = c.tunnel_id
      WHERE t.gateway_id IN (##1::server_id) AND c.connection_type = 'ssh';
      """

      gateway1 = Server.ID.generate()
      gateway2 = Server.ID.generate()

      target1 = Server.ID.generate()
      target2 = Server.ID.generate()
      target3 = Server.ID.generate()

      bounce1 = Server.ID.generate()
      bounce2 = Server.ID.generate()

      g2_bounces = [bounce1, bounce2]

      gateway1_opts = [fake_servers: true, gateway_id: gateway1]
      gateway2_opts =
        [fake_servers: true, gateway_id: gateway2, bounces: g2_bounces]

      {tun_g1t1, _} =
        NetworkSetup.tunnel(gateway1_opts ++ [destination_id: target1])
      {tun_g1t2, _} =
        NetworkSetup.tunnel(gateway1_opts ++ [destination_id: target2])
      {tun_g2t1, _} =
        NetworkSetup.tunnel(gateway2_opts ++ [destination_id: target1])
      {tun_g2t3, _} =
        NetworkSetup.tunnel(gateway2_opts ++ [destination_id: target3])

      # g1<>t1 has SSH connection
      NetworkSetup.connection([tunnel_id: tun_g1t1.tunnel_id, type: :ssh])

      # g1<>t2 has SSH connection
      NetworkSetup.connection([tunnel_id: tun_g1t2.tunnel_id, type: :ssh])
      NetworkSetup.connection([tunnel_id: tun_g1t2.tunnel_id, type: :ftp])

      # g2<>t1 does not have SSH connection
      NetworkSetup.connection([tunnel_id: tun_g2t1.tunnel_id, type: :ftp])

      # g2<>t3 has SSH connection
      NetworkSetup.connection([tunnel_id: tun_g2t3.tunnel_id, type: :ssh])

      expected1 = Enum.sort([
        %{destination_id: target2, gateway_id: gateway1, bounce_id: []},
        %{destination_id: target1, gateway_id: gateway1, bounce_id: []}
      ])

      g2_bounces = Enum.reverse(g2_bounces)
      expected2 = Enum.sort([
        %{destination_id: target3, gateway_id: gateway2, bounce_id: g2_bounces}
      ])

      {sql, {gateway1, expected1}, {gateway2, expected2}}
    end
  end

  describe "query/3" do

    test "all" do
      caster = fn type, value ->
        case type do
          :file_id ->
            File.ID.cast!(value) && to_string(value)
          :server_id ->
            Server.ID.cast!(value) && to_string(value)
          :fail_me ->
            {:error, :bad_value}
          _ ->
            to_string(value)
        end
      end

      f_id = File.ID.generate()
      s_id = Storage.ID.generate()

      sql1 = "SELECT * FROM files WHERE nome = 'abc'"
      p1 = []
      r1 = "SELECT * FROM files WHERE nome = 'abc'"

      sql2 = "SELECT * FROM files WHERE nome = ##1"
      p2 = ["nerdola"]
      r2 = "SELECT * FROM files WHERE nome = 'nerdola'"

      sql3 = "SELECT * FROM foo WHERE bar = ##1::file_id"
      p3 = [f_id]
      r3 = "SELECT * FROM foo WHERE bar = '" <> to_string(f_id) <> "'"

      sql4 = "SELECT * FROM the.who WHERE nome = ##1 AND status = ##2"
      p4 = ["renatu", "viadu"]
      r4 = "SELECT * FROM the.who WHERE nome = 'renatu' AND status = 'viadu'"

      sql5 = "SELECT * FROM files WHERE nome = ##1::wat AND carro = ##2"
      p5 = ["af", "fwef"]
      r5 = "SELECT * FROM files WHERE nome = 'af' AND carro = 'fwef'"

      sql6 = "
      SELECT DISTINCT t.gateway_id, t.destination_id, (
      SELECT ARRAY_REMOVE(ARRAY_AGG(source_id), t.gateway_id)
      FROM links
      WHERE tunnel_id = t.tunnel_id) as bounces
      FROM tunnels t
      INNER JOIN connections c
      ON t.tunnel_id = c.tunnel_id
      WHERE t.gateway_id IN (##1::server_id) AND c.connection_type = 'ssh';
      "
      p6 = ["::f"]
      r6 = "
      SELECT DISTINCT t.gateway_id, t.destination_id, (
      SELECT ARRAY_REMOVE(ARRAY_AGG(source_id), t.gateway_id)
      FROM links
      WHERE tunnel_id = t.tunnel_id) as bounces
      FROM tunnels t
      INNER JOIN connections c
      ON t.tunnel_id = c.tunnel_id
      WHERE t.gateway_id IN ('::f') AND c.connection_type = 'ssh';
      "

      sql7 = "
      SELECT *
      FROM file_modules 
      WHERE file_id =
        (SELECT f.file_id
        FROM files AS f
        LEFT JOIN file_modules AS fm ON f.file_id = fm.file_id
        WHERE f.storage_id = ##1::storage_id AND fm.name = ##2
        ORDER BY f.version DESC
        LIMIT 1)
      "
      p7 = [s_id, "wut"]
      r7 = "
      SELECT *
      FROM file_modules 
      WHERE file_id =
        (SELECT f.file_id
        FROM files AS f
        LEFT JOIN file_modules AS fm ON f.file_id = fm.file_id
        WHERE f.storage_id = '" <> to_string(s_id) <> "' AND fm.name = 'wut'
        ORDER BY f.version DESC
        LIMIT 1)
      "

      sql8 = "SELECT purpose FROM life WHERE ssn = ##1::fail_me"
      p8 = ["invalid"]
      r8 = :bad_value

      sql9 = "SELECT foo FROM bar WHERE name = ##1"
      p9 = ["std_caster"]
      r9 = "SELECT foo FROM bar WHERE name = 'std_caster'"

      sql10 = "SELECT foo FROM bar WHERE name = ##1::std_caster_ignores_types"
      p10 = [2]
      r10 = "SELECT foo FROM bar WHERE name = '2'"

      # Generates all queries
      assert {:ok, q1} = Hector.query(sql1, p1, caster)
      assert {:ok, q2} = Hector.query(sql2, p2, caster)
      assert {:ok, q3} = Hector.query(sql3, p3, caster)
      assert {:ok, q4} = Hector.query(sql4, p4, caster)
      assert {:ok, q5} = Hector.query(sql5, p5, caster)
      assert {:ok, q6} = Hector.query(sql6, p6, caster)
      assert {:ok, q7} = Hector.query(sql7, p7, caster)
      assert {:error, q8} = Hector.query(sql8, p8, caster)
      assert {:ok, q9} = Hector.query(sql9, p9)
      assert {:ok, q10} = Hector.query(sql10, p10)

      # Verifies that the generated queries are identical to the expected ones.
      assert q1 == r1
      assert q2 == r2
      assert q3 == r3
      assert q4 == r4
      assert q5 == r5
      assert q6 == format_sql(r6)
      assert q7 == format_sql(r7)
      assert q8 == r8
      assert q9 == r9
      assert q10 == r10
    end

    # Removes unnecessary spaces and line breaks. "trim on asteroids"
    defp format_sql(sql) do
      sql
      |> String.replace("\n", " ")
      |> remove_extra_spaces()
    end

    defp remove_extra_spaces(sql) do
      if String.contains?(sql, "  ") do
        sql
        |> String.replace("  ", " ")
        |> remove_extra_spaces()
      else
        sql
      end
    end
  end
end

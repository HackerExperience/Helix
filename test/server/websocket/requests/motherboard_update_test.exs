defmodule Helix.Server.Websocket.Requests.MotherboardUpdateTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Component
  alias Helix.Server.Websocket.Requests.MotherboardUpdate,
    as: MotherboardUpdateRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  @mock_socket ChannelSetup.mock_server_socket(access_type: :local)

  describe "MotherboardUpdateRequest.check_params" do
    test "casts the params to internal Helix format" do
      params =
        %{
          "motherboard_id" => "::1",
          "slots" => %{
            "cpu_1" => "::f",
            "ram_1" => nil,
          },
          "network_connections" => %{
            "::5" => %{
              "network_id" => "::",
              "ip" => "1.2.3.4"
            }
          }
        }

      req = MotherboardUpdateRequest.new(params)
      assert {:ok, req} = Requestable.check_params(req, @mock_socket)

      assert req.params.cmd == :update
      assert req.params.mobo_id == Component.ID.cast!(params["motherboard_id"])
      assert req.params.slots.cpu_1 == Component.ID.cast!("::f")
      refute req.params.slots.ram_1

      [{nic_id, nip}] = req.params.network_connections

      assert nic_id == Component.ID.cast!("::5")
      assert nip == {"1.2.3.4", Network.ID.cast!("::")}
    end

    test "handles invalid slot data" do
      base_params = %{"motherboard_id" => "::"}

      # Invalid component type `notexists`
      p1 =
        %{
          "slots" => %{"notexists_50" => "::"}
        } |> Map.merge(base_params)

      # Invalid slot `abc`
      p2 =
        %{
          "slots" => %{"cpu_abc" => nil}
        } |> Map.merge(base_params)

      # Invalid component ID `wtf`
      p3 =
        %{
          "slots" => %{"cpu_1" => "wtf"}
        } |> Map.merge(base_params)

      # Empty slots
      p4 = base_params

      req1 = MotherboardUpdateRequest.new(p1)
      req2 = MotherboardUpdateRequest.new(p2)
      req3 = MotherboardUpdateRequest.new(p3)
      req4 = MotherboardUpdateRequest.new(p4)

      assert {:error, %{message: reason1}, _} =
        Requestable.check_params(req1, @mock_socket)
      assert {:error, %{message: reason2}, _} =
        Requestable.check_params(req2, @mock_socket)
      assert {:error, %{message: reason3}, _} =
        Requestable.check_params(req3, @mock_socket)
      assert {:error, %{message: reason4}, _} =
        Requestable.check_params(req4, @mock_socket)

      assert reason1 == "bad_slot_data"
      assert reason2 == reason1
      assert reason3 == reason2
      assert reason4 == reason3
    end

    test "handles invalid network connections" do
      base_params =
        %{
          "motherboard_id" => "::f",
          "slots" => %{"cpu_1" => "::1"},
        }

      # Empty NCs
      p1 = base_params

      # Invalid NIC ID
      p2 =
        %{
          "network_connections" => %{
            "invalid_component" => %{
              "ip" => "1.2.3.4",
              "network_id" => "::"
            }
          }
        } |> Map.merge(base_params)

      # Invalid IP
      p3 =
        %{
          "network_connections" => %{
            "::f" => %{
              "ip" => "abc",
              "network_id" => "::"
            }
          }
        } |> Map.merge(base_params)

      # Invalid network ID
      p4 =
        %{
          "network_connections" => %{
            "::f" => %{
              "ip" => "127.0.0.1",
              "network_id" => "invalid"
            }
          }
        } |> Map.merge(base_params)

      req1 = MotherboardUpdateRequest.new(p1)
      req2 = MotherboardUpdateRequest.new(p2)
      req3 = MotherboardUpdateRequest.new(p3)
      req4 = MotherboardUpdateRequest.new(p4)

      assert {:error, %{message: reason1}, _} =
        Requestable.check_params(req1, @mock_socket)
      assert {:error, %{message: reason2}, _} =
        Requestable.check_params(req2, @mock_socket)
      assert {:error, %{message: reason3}, _} =
        Requestable.check_params(req3, @mock_socket)
      assert {:error, %{message: reason4}, _} =
        Requestable.check_params(req4, @mock_socket)

      assert reason1 == "bad_network_connections"
      assert reason2 == reason1
      assert reason3 == reason2
      assert reason4 == reason3
    end
  end
end

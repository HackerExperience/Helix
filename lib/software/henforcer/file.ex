defmodule Helix.Software.Henforcer.File do

  defmodule Cracker do

    alias HELL.IPv4
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server

    @spec can_bruteforce(Server.id, IPv4.t, Network.id, IPv4.t) ::
      :ok
      | {:error, {:target, :self}}
    def can_bruteforce(_source_id, source_ip, _network_id, target_ip) do
      # TODO: Check for noob protection
      if source_ip == target_ip do
        {:error, {:target, :self}}
      else
        :ok
      end
    end

  end

end

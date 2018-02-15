import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.Virus.Collect do

  import HELL.Macros

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer
  alias Helix.Network.Model.Bounce
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Software.Model.File
  alias Helix.Software.Henforcer.Virus, as: VirusHenforcer
  alias Helix.Software.Public.Virus, as: VirusPublic

  def check_params(request, socket) do
    check_account_info =
      fn atm_id, acc ->
        (is_nil(atm_id) and is_nil(acc)) or
        (not is_nil(atm_id) and not is_nil(acc))
      end

    wallet = nil  # #244

    with \
      {:ok, gateway_id} <- Server.ID.cast(request.unsafe["gateway_id"]),
      {:ok, bounce_id} <- cast_optional(request, :bounce_id, &Bounce.ID.cast/1),
      {:ok, atm_id} <- cast_optional(request, :atm_id, &Server.ID.cast/1),
      {:ok, viruses} <-
         cast_list_of_ids(request.unsafe["viruses"], &File.ID.cast/1),
      {:ok, account_number} <-
        cast_optional(request, :account_number, &BankAccount.cast/1),

      # Ensure that payment info includes at least one of bank account / wallet
      # And in the case of bank account, it includes the full information
      true <- valid_payment_info?({atm_id, account_number}, wallet),
      true <- valid_bank_info?(atm_id, account_number),

      # Viruses must not be an empty list
      false <- Enum.empty?(viruses)
    do
      params =
        %{
          gateway_id: gateway_id,
          viruses: viruses,
          bounce_id: bounce_id,
          atm_id: atm_id,
          account_number: account_number,
          wallet: wallet
        }

      update_params(request, params, reply: true)
    else
      {:bad_id, _} ->
        reply_error(request, :bad_virus)

      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    entity_id = socket.assigns.entity_id
    gateway_id = request.params.gateway_id
    viruses = request.params.viruses
    bounce_id = request.params.bounce_id
    atm_id = request.params.atm_id
    account_number = request.params.account_number
    wallet = request.params.wallet

    with \
      {true, r1} <- EntityHenforcer.owns_server?(entity_id, gateway_id),
      entity = r1.entity,
      gateway = r1.server,

      {true, r2} <- BankHenforcer.account_exists?(atm_id, account_number),
      bank_account = r2.bank_account,
      {true, _} <- EntityHenforcer.owns_bank_account?(entity, bank_account),

      payment_info = {bank_account, wallet},

      {true, r3} <-
        VirusHenforcer.can_collect_all?(entity, viruses, payment_info),
      viruses = r3.viruses,

      {true, r4} <- BounceHenforcer.can_use_bounce?(entity, bounce_id),
      bounce = r4.bounce
    do
      meta =
        %{
          viruses: viruses,
          gateway: gateway,
          payment_info: payment_info,
          bounce: bounce
        }

      update_meta(request, meta, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, _socket) do
    gateway = request.meta.gateway
    bounce = request.meta.bounce
    payment_info = request.meta.payment_info
    viruses = request.meta.viruses
    relay = request.relay

    # `VirusPublic.start_collect/5` expects [{File.t, Server.t}]
    viruses =
      Enum.reduce(viruses, [], fn %{file: file}, acc ->
        # OPTIMIZE: There's room for optimization here by bulk-fetching the
        # required data.
        server =
          file.storage_id
          |> CacheQuery.from_storage_get_server!()
          |> ServerQuery.fetch()

        acc ++ [{file, server}]
      end)

    hespawn fn ->
      VirusPublic.start_collect(
        gateway, viruses, bounce.bounce_id, payment_info, relay
      )
    end

    reply_ok(request)
  end

  render_empty()

  defp valid_bank_info?(nil, nil),
    do: true
  defp valid_bank_info?(atm, acc) when not is_nil(atm) and not is_nil(acc),
    do: true
  defp valid_bank_info?(_, _),
    do: false

  defp valid_payment_info?({nil, nil}, nil),
    do: false
  defp valid_payment_info?(_, _),
    do: true
end

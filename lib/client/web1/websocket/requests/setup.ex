import Helix.Websocket.Request

request Helix.Client.Web1.Websocket.Requests.Setup do

  alias Helix.Client.Web1.Model.Setup
  alias Helix.Client.Web1.Public, as: Web1Public

  @valid_pages_str Enum.map(Setup.valid_pages(), &to_string/1)

  def check_params(request, _socket) do
    valid_page? = fn ->
      Enum.all?(request.unsafe["pages"], &(&1 in @valid_pages_str))
    end

    with \
      true <- not is_nil(request.unsafe["pages"]),
      true <- valid_page?.() || :bad_page,
      pages = Enum.map(request.unsafe["pages"], &String.to_existing_atom/1)
    do
      update_params(request, %{pages: pages}, reply: true)
    else
      :bad_page ->
        reply_error("invalid_page")

      _ ->
        bad_request()
    end
  end

  def check_permissions(request, _socket),
    do: {:ok, request}

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id
    pages = request.params.pages

    case Web1Public.add_setup_pages(entity_id, pages) do
      {:ok, _} ->
        reply_ok(request)

      {:error, reason} ->
        reply_error(reason)
    end
  end

  render_empty()
end

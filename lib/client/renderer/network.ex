defmodule Helix.Client.Renderer.Network do

  alias HELL.ClientUtils
  alias HELL.HETypes
  alias Helix.Network.Model.Bounce

  @type rendered_bounce ::
    %{
      bounce_id: String.t,
      name: String.t,
      links: [HETypes.client_nip]
    }

  @spec render_bounce(Bounce.t) ::
    rendered_bounce
  def render_bounce(bounce = %Bounce{}) do
    links =
      bounce.links
      |> Enum.map(fn {_, network_id, ip} ->
        {network_id, ip}
      end)
      |> Enum.map(&ClientUtils.to_nip/1)

    %{
      bounce_id: to_string(bounce.bounce_id),
      name: bounce.name,
      links: links
    }
  end
end

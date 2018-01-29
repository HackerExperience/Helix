defmodule Helix.Client.Renderer do

  alias Helix.Client.Renderer.Network, as: NetworkRenderer

  @type rendered_bounce :: NetworkRenderer.rendered_bounce

  defdelegate render_bounce(bounce),
    to: NetworkRenderer
end

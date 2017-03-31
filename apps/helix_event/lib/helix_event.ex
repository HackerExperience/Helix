defmodule Helix.Event do

  use HELF.Event

  alias Helix.Software.Model.SoftwareType.Encryptor
  alias Helix.Software.Service.Event, as: SoftwareEvent

  # TODO: This type belongs to HELF.Event
  @type t :: struct

  event Encryptor.ProcessConclusionEvent, SoftwareEvent.Encryptor, :complete
end

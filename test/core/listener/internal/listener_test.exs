defmodule Helix.Core.Listener.Internal.ListenerTest do

  use Helix.Test.Case.Integration

  alias Helix.Core.Listener.Internal.Listener, as: ListenerInternal

  alias Helix.Test.Core.Listener.Setup, as: ListenerSetup

  describe "listen/6" do
    test "creates both Listener and Owner entries" do
      owner_id = "owwwwwwner"
      subscriber = "watter"
      object_id = "my_special_object"
      event = "Helix.Software.Event.File.Downloaded"
      callback = {"Helix.Core.Listener", "react_to_event"}
      meta = %{a: :b}

      assert {:ok, listener} =
        ListenerInternal.listen(
          object_id, event, callback, meta, owner_id, subscriber
        )

      assert listener.listener_id
      assert listener.object_id == object_id

      # Event was hashed (md5)
      refute listener.event == event

      # Make sure the Owner entry was created too
      # assert OwnerInternal.fetch()  # Parei aqui

      assert %{owner: owner} =
        ListenerInternal.fetch_owner(
          owner_id, object_id, listener.event, subscriber
        )

      assert owner.listener_id == listener.listener_id
      assert owner.owner_id == owner_id
      assert owner.object_id == object_id
      assert owner.event == listener.event
      assert owner.subscriber == subscriber
    end
  end

  describe "get_listeners/2" do
    test "returns all matching listeners" do

      # Listener 1
      {listener1, %{event: event1}} = ListenerSetup.listener()

      # Listener 2 listens to the same event on the same object, but with
      # different callbacks
      {_listener2, _} =
        ListenerSetup.listener(object_id: listener1.object_id, event: event1)

      # Listener 3 listens on the same object, but to a different event.
      {_listener3, _} = ListenerSetup.listener(object_id: listener1.object_id)

      listeners = ListenerInternal.get_listeners(listener1.object_id, event1)

      # Found 2 matching listeners
      assert length(listeners) == 2

      Enum.each(listeners, fn listen ->
        assert listen.module
        assert listen.method
        assert Map.has_key?(listen, :meta)
      end)
    end

    test "returns empty when no matches were found" do
      assert [] == ListenerInternal.get_listeners("wat", "taw")
    end
  end

  describe "unlisten/4" do
    test "removes both listener and owner entries" do
      {listener, %{params: params, event: event}} = ListenerSetup.listener()

      assert ListenerInternal.fetch_owner(
        params.owner_id, listener.object_id, listener.event, params.subscriber
      )

      ListenerInternal.unlisten(
        params.owner_id, listener.object_id, event, params.subscriber
      )

      refute ListenerInternal.fetch_owner(
        params.owner_id, listener.object_id, listener.event, params.subscriber
      )
    end
  end
end

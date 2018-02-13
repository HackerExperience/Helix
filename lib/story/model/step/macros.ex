# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Story.Model.Step.Macros do
  @moduledoc """
  Macros for the Step DSL.

  You probably don't want to mess with this module directly. Read the Steppable
  documentation instead.
  """

  import HELL.Macros

  alias HELL.Constant
  alias HELL.Utils
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent
  alias Helix.Story.Event.Email.Sent, as: StoryEmailSentEvent
  alias Helix.Story.Event.Reply.Sent, as: StoryReplySentEvent
  alias Helix.Story.Event.Step.ActionRequested, as: StepActionRequestedEvent

  defmacro step(name, contact \\ nil, do: block) do
    quote location: :keep do
      defmodule unquote(name) do
        @moduledoc false

        require Helix.Story.Model.Step

        Helix.Story.Model.Step.register()

        defimpl Helix.Story.Model.Steppable do
          @moduledoc false

          import HELL.Macros

          alias Helix.Event
          alias Helix.Story.Make.Story, as: StoryMake

          @emails Module.get_attribute(__MODULE__, :emails) || %{}
          @replies Module.get_attribute(__MODULE__, :replies) || %{}
          @contact get_contact(unquote(contact), __MODULE__)
          @step_name Helix.Story.Model.Step.get_name(unquote(name))

          unquote(block)

          # Most steps do not have a "restart" option. Those who do must
          # manually implement this protocol function.
          @doc false
          def restart(_step, _, _),
            do: raise "Undefined restart handler at #{inspect unquote(__MODULE__)}"

          # Catch-all for unhandled events, otherwise any unexpected event would
          # thrown an exception here.
          @doc false
          def handle_event(step, _event, _meta),
            do: {:noop, step, []}

          @doc false
          def format_meta(%{meta: meta}),
            do: meta

          @doc false
          def get_contact(_),
            do: @contact

          @doc false
          def get_emails(_),
            do: @emails

          @spec get_replies_of(Step.t, Step.email_id | Step.reply_id) ::
            [Step.reply_id]
          @doc """
          Returns valid replies for the given message (which may be either an
          `email_id` or a `reply_id`).

          Note that it checks for statically valid replies, so it DOES NOT CHECK
          LOCKED REPLIES.
          """
          def get_replies_of(_step, message_id) do
            cond do
              email = Map.get(@emails, message_id, false) ->
                email.replies

              replies = Map.get(@replies, message_id, false) ->
                replies.replies

              true ->
                []
            end
          end

          docp """
          It may be the case that `handle_callback` receives a result that has
          already been handled by itself. This happens when `relay_callback` is
          used. In this case, we simply return the input, since it's ready.
          """
          @spec handle_callback({:ok, [Event.t]}, term, term) ::
            {:ok, [Event.t]}
          defp handle_callback({:ok, events}, _, _),
            do: {:ok, events}

          docp """
          `handle_callback/3` will receive the result of a callback, which must
          return a `Step.callback_action`, and encapsulate it into a correct
          `StepActionRequestedEvent`, so it can be dispatched and ~eventually~
          handled by StoryHandler.
          """
          @spec handle_callback(
            {Step.callback_action, [Event.t]}, Entity.id, Step.contact)
          ::
            {:ok, [Event.t]}
          defp handle_callback({action, events}, entity_id, contact_id) do
            request_action =
              StepActionRequestedEvent.new(action, entity_id, contact_id)

            {:ok, events ++ [request_action]}
          end

          @doc """
          Predefined callback when user asks to `:complete` a step.
          """
          callback :cb_complete do
            {:complete, []}
          end

          @doc """
          Predefined callback when user asks to `:send_email`. `meta` must
          contain required data, in this case at least `email_id`.
          """
          callback :cb_send_email, _event, meta = %{email_id: email_id} do
            email_meta = Map.get(meta, :email_meta, %{})

            {{:send_email, email_id, email_meta, []}, []}
          end

          @doc """
          Predefined callback when user asks to `:send_reply`. `meta` must
          contain required data, in this case at least `reply_id`.
          """
          callback :cb_send_reply, _event, %{reply_id: reply_id} do
            {{:send_reply, reply_id, []}, []}
          end

          @doc """
          Predefined callback that is used by `on_process_started` listener.
          """
          callback :cb_process_started, event, meta do
            if to_string(event.process.type) == meta.type do
              relay_callback meta.relay_cb, event, meta
            else
              {:noop, []}
            end
          end
        end
      end
    end
  end

  @doc """
  Generates a callback ready to be executed as a response for some element that
  is being listened through `story_listen`.
  """
  defmacro callback(
    name,
    event \\ quote(do: _),
    meta \\ quote(do: _),
    do: block)
  do
    quote do

      def unquote(name)(var!(event) = unquote(event), meta = unquote(meta)) do
        step_entity_id = meta.step_entity_id |> Entity.ID.cast!()
        step_contact_id = meta.step_contact_id |> String.to_existing_atom()

        var!(event)  # Mark as used

        unquote(block)
        |> handle_callback(step_entity_id, step_contact_id)
      end

    end
  end

  @doc """
  `relay_callback` is a helper used when one callback is supposed to call
  another one, acting like a proxy.

  It may be rendered useless if we ever add some way to filter results of
  `Listener`. See the `cb_process_started` to understand why.
  """
  defmacro relay_callback(callback, event, meta) do
    quote do
      cb_fun = String.to_existing_atom(unquote(callback))

      apply(__MODULE__, cb_fun, [unquote(event), unquote(meta)])
    end
  end

  @doc """
  Executes `callback` when `event` happens over `element_id`.

  It's a wrapper for `Core.Listener`.
  """
  defmacro story_listen(element_id, events, meta \\ quote(do: %{}), callback) do
    # Import `Helix.Core.Listener` only once within the Step context (ENV)
    macro = has_macro?(__CALLER__, Helix.Core.Listener)
    import_block = macro && [] ||  quote(do: import Helix.Core.Listener)

    quote do

      unquote(import_block)

      {callback_name, extra_meta} = get_callback_data(unquote(callback))

      listen_meta =
        %{
          step_entity_id: var!(step).entity_id,
          step_contact_id: var!(step).contact
        }
        |> Map.merge(unquote(meta))
        |> Map.merge(extra_meta)

      listen unquote(element_id), unquote(events), callback_name,
        owner_id: var!(step).entity_id,
        subscriber: @step_name,
        meta: listen_meta

    end
  end

  @doc """
  Listener that triggers once the process of type `type` acts over `element_id`.
  """
  defmacro on_process_started(type, element_id, callback) do
    quote do

      {callback_name, extra_meta} = get_callback_data(unquote(callback))

      meta =
        %{
          type: unquote(type),
          relay_cb: callback_name
        }
        |> Map.merge(extra_meta)

      story_listen unquote(element_id), ProcessCreatedEvent,
        meta, :cb_process_started
    end
  end

  @doc """
  Formats the step metadata, automatically handling empty maps or atomizing
  existing map keys.
  """
  defmacro format_meta(do: block) do
    quote do

      @doc false
      def format_meta(%{meta: empty_map}) when empty_map ==  %{},
        do: %{}

      @doc false
      def format_meta(%{meta: meta}) do
        var!(meta) = HELL.MapUtils.atomize_keys(meta)
        unquote(block)
      end

    end
  end

  @doc """
  Public interface that should be used by the step to point to the next one.

  Steps are linked lists. Mind == blown.
  """
  defmacro next_step(next_step_module) do
    quote do
      # unless Code.ensure_compiled?(unquote(next_step_module)) do
      #   raise "The step #{inspect unquote(next_step_module)} does not exist"
      # end
      # Verification above is only possible if
      #   1 - We manage to verify on a second round of compilation; OR
      #   2 - We can force the `step_module` to be compiled first; OR
      #   3 - We store each step on a separate file; OR
      #   4 - We sort steps.ex from the last to the first step.
      # I don't want neither 3 or 4. Waiting for a cool hack on 1 or 2.

      @doc """
      Returns the next step module name (#{inspect unquote(next_step_module)}).
      """
      def next_step(_),
        do: Helix.Story.Model.Step.get_name(unquote(next_step_module))
    end
  end

  @doc """
  Defines a new email for the step.
  """
  defmacro email(email_id, opts \\ []) do
    prev_emails = get_emails(__CALLER__) || %{}
    email = add_email(email_id, opts)

    emails = Map.merge(prev_emails, email)

    set_emails(__CALLER__, emails)
  end

  @doc """
  Defines a new reply for the step.
  """
  defmacro reply(reply_id, opts \\ []) do
    prev_replies = get_replies(__CALLER__) || %{}
    reply = add_reply(reply_id, opts)

    replies = Map.merge(prev_replies, reply)

    set_replies(__CALLER__, replies)
  end

  @doc """
  Helper used to send an email from the step.
  """
  defmacro send_email(step, email_id, email_meta \\ quote(do: %{})) do
    emails = get_emails(__CALLER__) || %{}

    unless email_exists?(emails, email_id) do
      raise \
        "cant send email #{inspect email_id} on step " <>
        "#{inspect __CALLER__.module}; undefined"
    end

    quote do
      {:ok, events} =
        StoryAction.send_email(
          unquote(step), unquote(email_id), unquote(email_meta)
        )

      events
    end
  end

  @doc """
  Filters any events (handled by StoryHandler), performing the requested action.

  It supports all `Step.callback_actions`, as well as custom behaviour (through
  the `do: block` option). The result will be handled by StoryHandler's
  `handle_action/2`, so it must return a valid `Step.callback_action`.
  """
  defmacro filter(step, event, meta, opts) do
    quote do

      @doc false
      def handle_event(step = unquote(step), unquote(event), unquote(meta)) do
        unquote(
          case opts do
            [do: block] ->
              block

            [reply: reply_id] ->
              quote do
                {{:send_reply, unquote(reply_id), []}, step, []}
              end

            [reply: reply_id, send_opts: send_opts] ->
              quote do
                {{:send_reply, unquote(reply_id), unquote(send_opts)}, step, []}
              end

            [send: email_id] ->
              quote do
                meta = Keyword.get(unquote(opts), :meta, %{})

                {{:send_email, unquote(email_id), meta, []}, step, []}
              end

            [send: email_id, send_opts: send_opts] ->
              quote do
                meta = Keyword.get(unquote(opts), :meta, %{})
                {
                  {:send_email, unquote(email_id), meta, unquote(send_opts)},
                  step,
                  []
                }
              end

            [do: :complete, send_opts: send_opts] ->
              quote do
                {{:complete, unquote(send_opts)}, step, []}
              end

            :complete ->
              quote do
                {:complete, step, []}
              end

            [restart: true, reason: reason, checkpoint: checkpoint] ->
              quote do
                {{:restart, unquote(reason), unquote(checkpoint)}, step, []}
              end
          end
        )
      end

    end
  end

  @doc """
  Interface used to declare what should happen when `reply_id` is received.
  """
  defmacro on_reply(reply_id, opts) do
    # Emails that can receive this reply
    emails = get_emails(__CALLER__)
    emails_with_reply = get_emails_with_reply(emails, reply_id)

    email_block =
      for email <- emails_with_reply do
        quote do

          filter(
            step,
            %StoryReplySentEvent{
              reply: %{id: unquote(reply_id)},
              reply_to: unquote(email)
            },
            _,
            unquote(opts)
          )

        end
      end

    # Replies that can receive this reply
    replies = get_replies(__CALLER__)
    replies_with_reply = get_replies_with_reply(replies, reply_id)

    reply_block =
      for reply <- replies_with_reply do
        quote do

          filter(
            step,
            %StoryReplySentEvent{
              reply: %{id: unquote(reply_id)},
              reply_to: unquote(reply)
            },
            _,
            unquote(opts)
          )

        end
      end

    [email_block] ++ [reply_block]
  end

  @doc """
  Interface used to declare what should happen when `email_id` is sent.
  """
  defmacro on_email(email_id, opts) do
    # Emails that can receive this reply
    quote do

      filter(
        step,
        %StoryEmailSentEvent{
          email: %{id: unquote(email_id)}
        },
        _,
        unquote(opts)
      )

    end
  end

  @doc """
  This macro is required so the elixir compiler does not complain about the
  module attribute not being used.
  """
  defmacro contact(contact_name) do
    quote do
      @contact unquote(contact_name)
    end
  end

  @doc """
  Helper (syntactic sugar) for steps that do not generate any data.
  """
  defmacro empty_setup do
    quote do

      @doc false
      def setup(_) do
        nil
      end

    end
  end

  @doc """
  `setup_once` is a helper to ease achieving idempotency on `Steppable.setup/1`.

  It's a thin wrapper around `StoryQuery.Setup`, which does the heavy work.
  """
  defmacro setup_once(object, identifier, do: block),
    do: do_setup_once(object, identifier, [], block)
  defmacro setup_once(object, identifier, opts, do: block),
    do: do_setup_once(object, identifier, opts, block)

  defp do_setup_once(object, id, opts, block) do
    fun_name = Utils.concat_atom(:find_, object)

    quote do
      result =
        apply(StoryQuery.Setup, unquote(fun_name), [unquote(id), unquote(opts)])

      with nil <- result do
        unquote(block)
      end
    end
  end

  @spec get_contact(String.t | Constant.t | nil, module :: term) ::
    contact :: Step.contact
  @doc """
  If the given contact is a string or atom, then the `step` explicitly specified
  a contact. On the other hand, if it's not a string/atom (defaults to `nil`),
  then no contact was specified at the step level. In this case, we'll fall back
  to the contact defined for the mission. This is the most common scenario.
  """
  def get_contact(contact, _) when is_binary(contact),
    do: String.to_atom(contact)
  def get_contact(contact, _) when not is_nil(contact),
    do: contact
  def get_contact(_, step_module) do
    mission_contact =
      step_module
      |> Module.split()
      |> Enum.drop(4)  # Remove protocol namespace
      |> Enum.drop(-1)  # Get parent
      |> Module.concat()
      |> Module.get_attribute(:contact)

    if is_nil(mission_contact),
      do: raise "No contact for top-level mission at #{inspect step_module}"

    get_contact(mission_contact, step_module)
  end

  @spec get_callback_data(term) ::
    {callback_name :: atom, extra_meta :: map}
  @doc """
  Helper that analyzes the `story_listen` opts and returns the corresponding
  callback name, as well as extra metadata that we should feed to the callback.
  """
  def get_callback_data(email: {email_id, email_meta}),
    do: {:cb_send_email, %{email_id: email_id, email_meta: email_meta}}
  def get_callback_data(email: email_id) when is_binary(email_id),
    do: {:cb_send_email, %{email_id: email_id}}
  def get_callback_data(reply: reply_id) when is_binary(reply_id),
    do: {:cb_send_reply, %{reply_id: reply_id}}
  def get_callback_data(:complete),
    do: {:cb_complete, %{}}
  def get_callback_data(callback) when is_atom(callback),
    do: {callback, %{}}

  @spec add_email(Step.email_id, term) ::
    Step.emails
  docp """
  Given an email id and its options, convert it to the internal format defined
  by `Step.emails`, which is a map using `email_id` as lookup key.
  """
  defp add_email(email_id, opts) do
    metadata = %{
      id: email_id,
      replies: Utils.ensure_list(opts[:replies]),
      locked: Utils.ensure_list(opts[:locked])
    }

    Map.put(%{}, email_id, metadata)
  end

  @spec get_emails(Macro.Env.t) ::
    Step.emails
    | nil
  docp """
  Helper to read the module attribute `emails`
  """
  defp get_emails(%Macro.Env{module: module}),
    do: Module.get_attribute(module, :emails)

  @spec get_emails_with_reply(Step.emails, Step.reply_id) ::
    [Step.email_id]
  docp """
  Helper used to identify all emails that can receive the given `reply_id`.

  It is used to generate the `handle_event` filter by the `on_reply` macro,
  ensuring that only the subset of (emails that expect reply_id) are pattern
  matched against.
  """
  defp get_emails_with_reply(emails, reply_id) do
    Enum.reduce(emails, [], fn {id, email}, acc ->
      cond do
        Enum.member?(email.replies, reply_id) ->
          acc ++ [id]
        Enum.member?(email.locked, reply_id) ->
          acc ++ [id]
        true ->
          acc
      end
    end)
  end

  @spec email_exists?(Step.emails, Step.email_id) ::
    boolean
  docp """
  Helper to check whether the given email has been defined
  """
  defp email_exists?(emails, email_id),
    do: Map.get(emails, email_id, false) && true

  @spec set_emails(Macro.Env.t, Step.emails) ::
    :ok
  docp """
  Helper to set the module attribute `emails`
  """
  defp set_emails(%Macro.Env{module: module}, emails),
    do: Module.put_attribute(module, :emails, emails)

  @spec add_reply(Step.reply_id, term) ::
    Step.replies
  docp """
  Given an reply id and its options, convert it to the internal format defined
  by `Step.replies`, which is a map using `reply_id` as lookup key.
  """
  defp add_reply(reply_id, opts) do
    metadata = %{
      id: reply_id,
      replies: Utils.ensure_list(opts[:replies]),
      locked: Utils.ensure_list(opts[:locked])
    }

    Map.put(%{}, reply_id, metadata)
  end

  @spec get_replies(Macro.Env.t) ::
    Step.replies
    | nil
  docp """
  Helper to read the module attribute `replies`
  """
  defp get_replies(%Macro.Env{module: module}),
    do: Module.get_attribute(module, :replies)

  @spec get_replies_with_reply(Step.replies | nil, Step.reply_id) ::
    [Step.reply_id]
  docp """
  Helper used to identify all replies that can receive the given `reply_id`.

  Similar to `get_emails_with_reply`, it's used by the `on_reply` macro.
  """
  defp get_replies_with_reply(nil, _),
    do: []
  defp get_replies_with_reply(replies, reply_id) do
    Enum.reduce(replies, [], fn {id, reply}, acc ->
      cond do
        Enum.member?(reply.replies, reply_id) ->
          acc ++ [id]
        Enum.member?(reply.locked, reply_id) ->
          acc ++ [id]
        true ->
          acc
      end
    end)
  end

  @spec set_replies(Macro.Env.t, Step.replies) ::
    :ok
  docp """
  Helper to set the module attribute `replies`
  """
  defp set_replies(%Macro.Env{module: module}, replies),
    do: Module.put_attribute(module, :replies, replies)

  @spec has_macro?(Macro.Env.t, module) ::
    boolean
  docp """
  Helper that checks whether the given module has already been imported
  """
  defp has_macro?(env, macro),
    do: Enum.any?(env.macros, fn {module, _} -> module == macro end)
end

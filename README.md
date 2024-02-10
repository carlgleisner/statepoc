# AshStateMachine PoC

This repository was set up to reproduce a potential issue.

The resource and its changes are copied from the [basic state machine](https://hexdocs.pm/ash_state_machine/get-started-with-state-machines.html#a-basic-state-machine) in the documentation for AshStateMachine.

## Steps to reproduce

Get dependencies and fire up an IEX session.

```sh
mix deps.get
iex -S mix
```

Create a ticket.

```elixir
iex(1)> ticket = Statepoc.Support.Ticket |> Ash.Changeset.for_create(:create) |> Statepoc.Support.create!()
#Statepoc.Support.Ticket<
  __meta__: #Ecto.Schema.Metadata<:loaded>,
  id: "61868f6d-1dc0-42d5-92c4-01eee81d6d29",
  error: nil,
  error_state: nil,
  state: :pending,
  aggregates: %{},
  calculations: %{},
  ...
>
```

Now the `Ticket` resource has a `change` that will hook in to `after_transaction/1` and pass through any successful updates but set the attributes `:error`and `:error_state` if receiving `changeset, {:error, error}`.

Both paths call `IO.inspect/2`.

```elixir
changes do
  change after_transaction(fn
            changeset, {:ok, result} ->
              IO.inspect("Got {:ok, result}", label: "after_transaction: ")
              {:ok, result}

            changeset, {:error, error} ->
              message = Exception.message(error)
              IO.inspect(message, label: "after_transaction: ")

              changeset.data
              |> Ash.Changeset.for_update(:error, %{
                message: message,
                error_state: changeset.data.state
              })
              |> Statepoc.Support.update()
          end),
          on: [:update]
end
```

Now trigger a legal state change and see the `IO.inspect/2` output.

```elixir
iex(2)> ticket = ticket |> Ash.Changeset.for_update(:confirm) |> Statepoc.Support.update!()
after_transaction: "Got {:ok, result}"
#Statepoc.Support.Ticket<
  __meta__: #Ecto.Schema.Metadata<:loaded>,
  id: "61868f6d-1dc0-42d5-92c4-01eee81d6d29",
  error: nil,
  error_state: nil,
  state: :confirmed,
  aggregates: %{},
  calculations: %{},
  ...
>
```

Great, it says `Got {:ok, result}` and the `state` attribute is updated.

Let's trigger an illegal state change to spice things up.

```elixir
iex(3)> ticket |> Ash.Changeset.for_update(:package_arrived) |> Statepoc.Support.update()
{:error,
 %Ash.Error.Invalid{
   errors: [
     %AshStateMachine.Errors.NoMatchingTransition{
       action: :package_arrived,
       target: :arrived,
       old_state: :confirmed,
       changeset: nil,
       query: nil,
       error_context: [],
       vars: [],
       path: [],
       stacktrace: #Stacktrace<>,
       class: :invalid
     }
   ],
   stacktraces?: true,
   changeset: #Ash.Changeset<
     action_type: :update,
     action: :package_arrived,
     attributes: %{},
     relationships: %{},
     errors: [
       %AshStateMachine.Errors.NoMatchingTransition{
         action: :package_arrived,
         target: :arrived,
         old_state: :confirmed,
         changeset: nil,
         query: nil,
         error_context: [],
         vars: [],
         path: [],
         stacktrace: #Stacktrace<>,
         class: :invalid
       }
     ],
     data: #Statepoc.Support.Ticket<
       __meta__: #Ecto.Schema.Metadata<:loaded>,
       id: "61868f6d-1dc0-42d5-92c4-01eee81d6d29",
       error: nil,
       error_state: nil,
       state: :confirmed,
       aggregates: %{},
       calculations: %{},
       ...
     >,
     context: %{actor: nil, authorize?: false},
     valid?: false
   >,
   query: nil,
   error_context: [nil],
   vars: [],
   path: [],
   stacktrace: #Stacktrace<>,
   class: :invalid
 }}
```

Great, we correctly get an error. However, the `after_transaction` doesn't appear to have been triggered since no message was logged to the terminal.

Querying all `Tickets` also reveals that the record hasn't been updated with the error as intended.

```elixir
iex(4)> require Ash.Query
Ash.Query
```

```elixir
iex(5)> Statepoc.Support.Ticket |> Statepoc.Support.read()
{:ok,
 [
   #Statepoc.Support.Ticket<
     __meta__: #Ecto.Schema.Metadata<:loaded>,
     id: "61868f6d-1dc0-42d5-92c4-01eee81d6d29",
     error: nil,
     error_state: nil,
     state: :confirmed,
     aggregates: %{},
     calculations: %{},
     ...
   >
 ]}
```

The attributes `error` and `error_state` are `nil` and no logging was triggered.

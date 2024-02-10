defmodule Statepoc.Support.Ticket do
  use Ash.Resource,
    extensions: [AshStateMachine]

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition :confirm, from: :pending, to: :confirmed
      transition :begin_delivery, from: :confirmed, to: :on_its_way
      transition :package_arrived, from: :on_its_way, to: :arrived
      transition :error, from: [:pending, :confirmed, :on_its_way], to: :error
    end
  end

  actions do
    defaults [:create, :read]

    update :confirm do
      change transition_state(:confirmed)
    end

    update :begin_delivery do
      change transition_state(:on_its_way)
    end

    update :package_arrived do
      change transition_state(:arrived)
    end

    update :error do
      accept [:error_state, :error]
      change transition_state(:error)
    end
  end

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

  attributes do
    uuid_primary_key :id
    attribute :error, :string
    attribute :error_state, :string
  end
end

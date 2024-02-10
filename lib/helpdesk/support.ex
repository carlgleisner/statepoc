defmodule Statepoc.Support do
  use Ash.Api

  resources do
    resource Statepoc.Support.Ticket
  end
end

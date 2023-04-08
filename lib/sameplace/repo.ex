defmodule Sameplace.Repo do
  use Ecto.Repo,
    otp_app: :sameplace,
    adapter: Ecto.Adapters.Postgres
end

defmodule Sameplace.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SameplaceWeb.Telemetry,
      # Start the Ecto repository
      Sameplace.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sameplace.PubSub},
      # Presence
      Sameplace.Presence,
      # Start Finch
      {Finch, name: Sameplace.Finch},
      # Start the Endpoint (http/https)
      SameplaceWeb.Endpoint
      # Start a worker by calling: Sameplace.Worker.start_link(arg)
      # {Sameplace.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sameplace.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SameplaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

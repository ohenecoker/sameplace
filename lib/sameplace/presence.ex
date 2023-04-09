defmodule Sameplace.Presence do
  use Phoenix.Presence,
    otp_app: :sameplace,
    pubsub_server: Sameplace.PubSub
end

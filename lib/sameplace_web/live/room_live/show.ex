defmodule SameplaceWeb.RoomLive.Show do
  use SameplaceWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias Sameplace.Organizer
  alias Sameplace.ConnectedUser
  alias Sameplace.Presence

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = create_connected_user()
    room = Organizer.get_room!(id)
    slug = room.slug
    Phoenix.PubSub.subscribe(Sameplace.PubSub, "room:#{slug}")
    Phoenix.PubSub.subscribe(Sameplace.PubSub, "room:#{slug}:#{user.uuid}")
    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, %{})

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Organizer.get_room!(id))
     |> assign(:user, user)
     |> assign(:slug, slug)
     |> assign(:connected_users, [])
     |> assign(:offer_requests, [])
     |> assign(:ice_candidate_offers, [])
     |> assign(:sdp_offers, [])
     |> assign(:answers, [])}
  end

  @impl true
  def handle_event("new_ice_candidate", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.uuid})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_ice_candidate", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_sdp_offer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.uuid})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_sdp_offer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_answer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.uuid})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_answer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("join_call", _params, socket) do
    for user <- socket.assigns.connected_users do
      send_direct_message(
        socket.assigns.slug,
        user,
        "request_offers",
        %{
          from_user: socket.assigns.user
        }
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{}, socket) do
    list_present(socket) |> IO.inspect()

    {:noreply,
     socket
     |> assign(:connected_users, list_present(socket))}
  end

  @impl true
  def handle_info(%Broadcast{event: "request_offers", payload: request}, socket) do
    {:noreply,
     socket
     |> assign(:offer_requests, socket.assigns.offer_requests ++ [request])}
  end

  @impl true
  def handle_info(%Broadcast{event: "new_ice_candidate", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:ice_candidate_offers, socket.assigns.ice_candidate_offers ++ [payload])}
  end

  @impl true
  def handle_info(%Broadcast{event: "new_sdp_offer", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:sdp_offers, socket.assigns.ice_candidate_offers ++ [payload])}
  end

  @impl true
  def handle_info(%Broadcast{event: "new_answer", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:answers, socket.assigns.answers ++ [payload])}
  end

  defp list_present(socket) do
    alias Sameplace.Presence

    Presence.list("room:#{socket.assigns.slug}")
    |> Enum.map(fn {k, _} -> k end)
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp create_connected_user do
    %ConnectedUser{uuid: Ecto.UUID.generate()}
  end

  defp send_direct_message(slug, to_user, event, payload) do
    SameplaceWeb.Endpoint.broadcast_from(
      self(),
      "room:" <> slug <> ":" <> to_user,
      event,
      payload
    )
  end
end

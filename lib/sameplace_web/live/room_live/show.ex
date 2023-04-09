defmodule SameplaceWeb.RoomLive.Show do
  use SameplaceWeb, :live_view

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
    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, %{})

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Organizer.get_room!(id))
     |> assign(:user, user)
     |> assign(:slug, slug)
     |> assign(:connected_users, [])}
  end

  @impl true
  def handle_info(%{}, socket) do
    list_present(socket) |> IO.inspect()

    {:noreply,
     socket
     |> assign(:connected_users, list_present(socket))}
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
end

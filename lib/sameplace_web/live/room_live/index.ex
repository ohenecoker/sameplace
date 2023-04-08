defmodule SameplaceWeb.RoomLive.Index do
  use SameplaceWeb, :live_view

  alias Sameplace.Organizer
  alias Sameplace.Organizer.Room

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :rooms, Organizer.list_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Organizer.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_info({SameplaceWeb.RoomLive.FormComponent, {:saved, room}}, socket) do
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Organizer.get_room!(id)
    {:ok, _} = Organizer.delete_room(room)

    {:noreply, stream_delete(socket, :rooms, room)}
  end

  @impl true
  # def handle_event("validate", %{"room" => room_params}, socket) do
  #   {:noreply,
  #    socket
  #    |> put_changeset(room_params)}
  # end

  # def handle_event("save", _, %{assigns: %{}} ) do

  # end

  # defp put_changeset(socket, params \\ %{}) do
  #   socket
  #   |> assign(:changeset, Room.changeset(%Room{}, params))
  # end
end

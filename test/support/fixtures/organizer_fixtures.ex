defmodule Sameplace.OrganizerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sameplace.Organizer` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        slug: "some slug",
        title: "some title"
      })
      |> Sameplace.Organizer.create_room()

    room
  end
end

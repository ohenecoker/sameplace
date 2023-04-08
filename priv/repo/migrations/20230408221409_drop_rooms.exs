defmodule Sameplace.Repo.Migrations.DropRooms do
  use Ecto.Migration

  def change do
    drop table(:rooms)
  end
end

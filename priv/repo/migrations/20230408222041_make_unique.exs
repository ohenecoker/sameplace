defmodule Sameplace.Repo.Migrations.MakeUnique do
  use Ecto.Migration

  def change do
    create unique_index(:rooms, :slug)
  end
end

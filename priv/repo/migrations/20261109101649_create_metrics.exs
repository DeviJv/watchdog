defmodule Watchdog.Repo.Migrations.CreateMatrics do
  use Ecto.Migration

  def change do
    create table(:metrics)  do
      add :url, :string, null: false
      add :time_ms, :integer, null: false
      add :status_code, :integer
      add :error_reason, :string

      timestamps()
    end
    create index(:metrics, [:url])
  end
end

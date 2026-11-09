defmodule Watchdog.Metric do
  use Ecto.Schema
  import Ecto.Changeset

  # Memetakan struct Elixir ke tabel fisik "metrics"
  schema "metrics" do
    field(:url, :string)
    field(:status_code, :integer)
    field(:time_ms, :integer)
    field(:error_reason, :string)

    timestamps()
  end

  @doc """
  Changeset adalah filter keamanan Ecto.
  Fungsi ini memastikan tidak ada data sampah yang masuk ke database.
  """
  def changeset(metric, attrs) do
    metric
    # cast: Hanya izinkan 4 kolom ini yang boleh diisi dari luar
    |> cast(attrs, [:url, :status_code, :time_ms, :error_reason])
    # validate_required: Tolak proses insert jika url atau time_ms kosong
    |> validate_required([:url, :time_ms])
  end
end

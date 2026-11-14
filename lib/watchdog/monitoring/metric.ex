defmodule Watchdog.Monitoring.Metric do
  use Ecto.Schema
  import Ecto.Changeset

  # Tambahkan baris ini HANYA (Standar Emas)
  # Tambahkan satu baris @derive ini persis sebelum pemanggilan schema "metrics" do.
  # Ini memberi tahu Jason cara otomatis mengubah struct Metric menjadi JSON
  # tanpa mengikutsertakan __meta__.
  @derive {Jason.Encoder, only: [:id, :url, :status_code, :time_ms, :error_reason, :inserted_at]}
  # fungsi @derive di atas sama seperti fungsi dibawah ini
  #   |> Enum.map(&(&1 |> Map.from_struct() |> Map.drop([:__meta__])))

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

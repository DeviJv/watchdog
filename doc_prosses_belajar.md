
    # looping setiap URL yg masuk
    #     Enum.each(urls, fn url ->
    #       Task.Supervisor.start_child(Watchdog.TaskSupervisor, fn ->
    #         # lakukan ping secara bersamaan
    #         hasil = Watchdog.ping(url)
    #
    #         # simpan hasil ke memory ETS!
    #         :ets.insert(:watchdog_metrics, {url, hasil})
    #
    #         IO.inspect(hasil, label: "Hasil Ping")
    #       end)
    #     end)

kode di atas asalnya ada di Watchdog.Scheduler.handle_info kode di atas tidak di pakai karna di ganti jadi  Task.Supervisor.async_stream bisa kamu lihat full nya di fungsi handle_info/2

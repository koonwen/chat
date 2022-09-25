open Chat.Client

let () =
  Cohttp_lwt_unix.Debug.activate_debug ();
  Logs.set_level (Some Logs.Warning);
  Lwt_main.run (connect ~host_uri:"http://localhost:8000")

open Chat.Server

let () =
  Cohttp_lwt_unix.Debug.activate_debug ();
  Logs.set_level (Some Warning);
  listen ()

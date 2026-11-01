// subfinder_tab.vala
// Subfinder install + run tab.
// Detects platform, checks Go, clones/installs subfinder, runs it inline or in terminal.

// https://github.com/projectdiscovery/subfinder

private string detect_platform () {
    // Check common platform indicators
    if (FileUtils.test ("/proc/version", FileTest.EXISTS)) return "linux";
    if (FileUtils.test ("/Applications", FileTest.EXISTS)) return "mac";
    return "windows";
}

private bool is_go_installed () {
    int status;
    try {
        Process.spawn_sync (null, {"which", "go"}, null,
            SpawnFlags.SEARCH_PATH | SpawnFlags.STDOUT_TO_DEV_NULL | SpawnFlags.STDERR_TO_DEV_NULL,
            null, null, null, out status);
        return status == 0;
    } catch {
        // Try 'where' for windows
        try {
            Process.spawn_sync (null, {"where", "go"}, null,
                SpawnFlags.SEARCH_PATH | SpawnFlags.STDOUT_TO_DEV_NULL | SpawnFlags.STDERR_TO_DEV_NULL,
                null, null, null, out status);
            return status == 0;
        } catch {
            return false;
        }
    }
}

private bool is_subfinder_installed () {
    int status;
    try {
        Process.spawn_sync (null, {"which", "subfinder"}, null,
            SpawnFlags.SEARCH_PATH | SpawnFlags.STDOUT_TO_DEV_NULL | SpawnFlags.STDERR_TO_DEV_NULL,
            null, null, null, out status);
        return status == 0;
    } catch {
        return false;
    }
}

private void append_output (Gtk.TextView view, string text) {
    var buf = view.get_buffer ();
    Gtk.TextIter end;
    buf.get_end_iter (out end);
    buf.insert (ref end, text, -1);
    // Scroll to bottom
    var mark = buf.get_insert ();
    view.scroll_to_mark (mark, 0.0, false, 0.0, 1.0);
}

private void clear_output (Gtk.TextView view) {
    view.get_buffer ().set_text ("", -1);
}

// Run a command and stream output into the TextView asynchronously
private async void run_command_async (string[] argv, Gtk.TextView output_view, Gtk.Button? lock_btn) {
    if (lock_btn != null) lock_btn.set_sensitive (false);

    try {
        int stdout_fd, stderr_fd;
        Pid child_pid;

        Process.spawn_async_with_pipes (
            null, argv, null,
            SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
            null,
            out child_pid,
            null,
            out stdout_fd,
            out stderr_fd
        );

        var stdout_channel = new IOChannel.unix_new (stdout_fd);
        var stderr_channel = new IOChannel.unix_new (stderr_fd);

        stdout_channel.add_watch (IOCondition.IN | IOCondition.HUP, (channel, cond) => {
            if (IOCondition.IN in cond) {
                string line;
                try {
                    channel.read_line (out line, null, null);
                    if (line != null)
                        append_output (output_view, line);
                } catch {}
            }
            return !(IOCondition.HUP in cond);
        });

        stderr_channel.add_watch (IOCondition.IN | IOCondition.HUP, (channel, cond) => {
            if (IOCondition.IN in cond) {
                string line;
                try {
                    channel.read_line (out line, null, null);
                    if (line != null)
                        append_output (output_view, "[stderr] " + line);
                } catch {}
            }
            return !(IOCondition.HUP in cond);
        });

        ChildWatch.add (child_pid, (pid, status) => {
            Process.close_pid (pid);
            int exit_code = Process.exit_status (status);
            append_output (output_view, "\n>> Process exited with code %d\n".printf (exit_code));
            if (lock_btn != null) lock_btn.set_sensitive (true);
        });

    } catch (Error e) {
        append_output (output_view, "Error: %s\n".printf (e.message));
        if (lock_btn != null) lock_btn.set_sensitive (true);
    }
}

// Open a new terminal window and run a command
private void run_in_terminal (string command, string platform) {
    try {
        string[] argv;
        if (platform == "linux") {
            // Try common terminals in order
            if (Environment.find_program_in_path ("gnome-terminal") != null)
                argv = {"gnome-terminal", "--", "bash", "-c", command + "; exec bash"};
            else if (Environment.find_program_in_path ("xterm") != null)
                argv = {"xterm", "-e", "bash -c '" + command + "; exec bash'"};
            else if (Environment.find_program_in_path ("konsole") != null)
                argv = {"konsole", "-e", "bash -c '" + command + "; exec bash'"};
            else if (Environment.find_program_in_path ("xfce4-terminal") != null)
                argv = {"xfce4-terminal", "-e", "bash -c '" + command + "; exec bash'"};
            else {
                argv = {"x-terminal-emulator", "-e", "bash -c '" + command + "; exec bash'"};
            }
        } else if (platform == "mac") {
            argv = {"osascript", "-e",
                "tell app \"Terminal\" to do script \"%s\"".printf (command)};
        } else {
            // Windows
            argv = {"cmd.exe", "/c", "start", "cmd.exe", "/k", command};
        }
        Process.spawn_async (null, argv, null,
            SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
            null, null);
    } catch (Error e) {
        stderr.printf ("Terminal error: %s\n", e.message);
    }
}

public Gtk.Widget build_subfinder_tab () {
    string platform = detect_platform ();

    var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
    box.set_margin_top (15);
    box.set_margin_bottom (15);
    box.set_margin_start (15);
    box.set_margin_end (15);

    // --- Status bar ---
    var status_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

    var go_status = new Gtk.Label ("");
    go_status.set_xalign (0);

    var sf_status = new Gtk.Label ("");
    sf_status.set_xalign (0);

    var platform_label = new Gtk.Label ("Platform: " + platform);
    platform_label.set_xalign (0);

    status_box.append (platform_label);
    status_box.append (go_status);
    status_box.append (sf_status);

    // Update status indicators
    void update_status () {
        bool go_ok = is_go_installed ();
        bool sf_ok = is_subfinder_installed ();
        go_status.set_text (go_ok ? "✅ Go installed" : "❌ Go not found");
        sf_status.set_text (sf_ok ? "✅ subfinder installed" : "⚠ subfinder not installed");
    }
    update_status ();

    // --- Button row ---
    var btn_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);

    var install_btn = new Gtk.Button.with_label ("⬇  Install subfinder");

    var run_inline_btn = new Gtk.Button.with_label ("▶  Run script");
    var run_external_btn = new Gtk.Button.with_label ("🖥  Run externally");

    var refresh_btn = new Gtk.Button.with_label ("↻  Refresh status");

    btn_row.append (install_btn);
    btn_row.append (run_inline_btn);
    btn_row.append (run_external_btn);
    btn_row.append (refresh_btn);

    // --- Command entry for "run script" ---
    var cmd_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    var cmd_label = new Gtk.Label ("Command:");
    cmd_label.set_xalign (0);
    var cmd_entry = new Gtk.Entry ();
    cmd_entry.set_text ("subfinder -h");
    cmd_entry.set_hexpand (true);
    cmd_row.append (cmd_label);
    cmd_row.append (cmd_entry);

    // --- Output area ---
    var scroll = new Gtk.ScrolledWindow ();
    scroll.set_vexpand (true);
    scroll.set_hexpand (true);
    scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

    var output = new Gtk.TextView ();
    output.set_editable (false);
    output.set_cursor_visible (false);
    output.set_monospace (true);
    output.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
    scroll.set_child (output);

    append_output (output, ">> SUBFINDER CONSOLE\n");
    append_output (output, "Platform detected: %s\n".printf (platform));
    append_output (output, is_go_installed ()
        ? "Go: found\n"
        : "Go: NOT FOUND — install from https://go.dev/dl/\n");
    append_output (output, is_subfinder_installed ()
        ? "subfinder: already installed\n"
        : "subfinder: not installed — click Install\n");
    append_output (output, "─────────────────────────────────\n");

    // --- Install button logic ---
    install_btn.clicked.connect (() => {
        if (!is_go_installed ()) {
            clear_output (output);
            append_output (output, "❌ Go is not installed.\n");
            append_output (output, "Please install Go first: https://go.dev/dl/\n");
            append_output (output, "After installing, restart the toolkit and try again.\n");
            return;
        }

        clear_output (output);
        append_output (output, ">> Starting subfinder installation...\n");
        append_output (output, "Running: go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest\n");
        append_output (output, "─────────────────────────────────\n");

        string[] argv = {
            "go", "install", "-v",
            "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        };

        run_command_async.begin (argv, output, install_btn, () => {
            update_status ();
        });
    });

    // --- Run inline button ---
    run_inline_btn.clicked.connect (() => {
        string cmd = cmd_entry.get_text ().strip ();
        if (cmd == "") return;

        clear_output (output);
        append_output (output, ">> Running: %s\n".printf (cmd));
        append_output (output, "─────────────────────────────────\n");

        // Split command into argv
        string[] argv = cmd.split (" ");
        run_command_async.begin (argv, output, run_inline_btn, () => {});
    });

    // --- Run externally button ---
    run_external_btn.clicked.connect (() => {
        string cmd = cmd_entry.get_text ().strip ();
        if (cmd == "") return;
        append_output (output, ">> Launching in external terminal: %s\n".printf (cmd));
        run_in_terminal (cmd, platform);
    });

    // --- Refresh button ---
    refresh_btn.clicked.connect (() => {
        update_status ();
        append_output (output, ">> Status refreshed\n");
    });

    box.append (status_box);
    box.append (btn_row);
    box.append (cmd_row);
    box.append (scroll);

    return box;
}

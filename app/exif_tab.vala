// exif_tab.vala
// UI for the Exif Hunter tab.

public Gtk.Widget build_exif_tab () {
    var exif_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
    exif_box.set_margin_top (15);
    exif_box.set_margin_bottom (15);
    exif_box.set_margin_start (15);
    exif_box.set_margin_end (15);

    var desc = new Gtk.Label ("Extract EXIF metadata from image files");
    desc.set_xalign (0);

    // --- File chooser row ---
    var file_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);

    var file_label = new Gtk.Label ("No file selected");
    file_label.set_xalign (0);
    file_label.set_hexpand (true);

    var choose_btn = new Gtk.Button.with_label ("Select Image…");

    file_row.append (choose_btn);
    file_row.append (file_label);

    // --- Scan button ---
    var scan_btn = new Gtk.Button.with_label ("Extract EXIF");
    scan_btn.set_sensitive (false);

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

    // Dark terminal style
    var css = new Gtk.CssProvider ();
    css.load_from_string (
        "textview { background-color: #0d1117; color: #39ff14; font-size: 13px; padding: 10px; } " +
        "textview text { background-color: #0d1117; color: #39ff14; }"
    );
    Gtk.StyleContext.add_provider_for_display (
        Gdk.Display.get_default (),
        css,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    scroll.set_child (output);

    // --- Map button (hidden until GPS found) ---
    var map_btn = new Gtk.Button.with_label ("🗺  Open Location in OpenStreetMap");
    map_btn.set_visible (false);

    // Store GPS coords for map button
    string gps_url = "";

    set_output (output, ">> EXIF_DATA_STREAM\nSelect an image file and press Extract EXIF.");

    string selected_file = "";

    choose_btn.clicked.connect (() => {
        var dialog = new Gtk.FileDialog ();
        dialog.set_title ("Select Image File");

        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("image/jpeg");
        filter.add_mime_type ("image/tiff");
        filter.add_pattern ("*.jpg");
        filter.add_pattern ("*.jpeg");
        filter.add_pattern ("*.tif");
        filter.add_pattern ("*.tiff");

        var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
        filters.append (filter);
        dialog.set_filters (filters);

        dialog.open.begin (null, null, (obj, res) => {
            try {
                var file = dialog.open.end (res);
                if (file != null) {
                    selected_file = file.get_path ();
                    file_label.set_text (file.get_basename ());
                    scan_btn.set_sensitive (true);
                    // Hide map button when new file is selected
                    map_btn.set_visible (false);
                    gps_url = "";
                }
            } catch (Error e) {
                // user cancelled
            }
        });
    });

    scan_btn.clicked.connect (() => {
        if (selected_file == "") return;

        ExifData data = parse_exif (selected_file);
        var sb = new StringBuilder ();

        sb.append (">> EXIF_DATA_STREAM\n");
        sb.append ("─────────────────────────────────\n");
        sb.append (@"DEVICE MODEL:  $(data.device_model)\n");
        sb.append (@"TIMESTAMP:     $(data.timestamp)\n");
        sb.append (@"SOFTWARE/OS:   $(data.software)\n");
        sb.append (@"EXPOSURE:      $(data.exposure)\n");
        sb.append (@"ISO SPEED:     $(data.iso)\n");
        sb.append ("─────────────────────────────────\n");

        if (data.has_gps) {
            // Convert to signed decimal for OSM URL
            double lat_val = parse_coord (data.gps_lat);
            double lon_val = parse_coord (data.gps_lon);

            // zoom=15 gives a nice street-level view
            gps_url = "https://www.openstreetmap.org/?mlat=%.6f&mlon=%.6f#map=15/%.6f/%.6f".printf (
                lat_val, lon_val, lat_val, lon_val
            );

            sb.append ("GPS LOCATION FOUND:\n");
            sb.append (@"  LATITUDE:    $(data.gps_lat)\n");
            sb.append (@"  LONGITUDE:   $(data.gps_lon)\n");
            sb.append (@"  OSM URL:     $gps_url\n");

            map_btn.set_visible (true);
        } else {
            sb.append ("NO GPS DATA FOUND IN IMAGE\n");
            map_btn.set_visible (false);
            gps_url = "";
        }

        set_output (output, sb.str);
    });

    map_btn.clicked.connect (() => {
        if (gps_url == "") return;
        try {
            AppInfo.launch_default_for_uri (gps_url, null);
        } catch (Error e) {
            stderr.printf ("Error opening map: %s\n", e.message);
        }
    });

    exif_box.append (desc);
    exif_box.append (file_row);
    exif_box.append (scan_btn);
    exif_box.append (scroll);
    exif_box.append (map_btn);

    return exif_box;
}

// Convert "51.507400°N" or "0.127800°W" to signed double
private double parse_coord (string coord) {
    string s = coord;
    bool negative = s.has_suffix ("S") || s.has_suffix ("W");
    s = s.replace ("°N","").replace ("°S","")
         .replace ("°E","").replace ("°W","").strip ();
    double val = double.parse (s);
    return negative ? -val : val;
}

private void set_output (Gtk.TextView view, string text) {
    view.get_buffer ().set_text (text, -1);
}

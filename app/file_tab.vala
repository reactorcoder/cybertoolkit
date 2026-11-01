// file_tab.vala
// UI for the File Hunter tab with Category + filetype dropdowns.

public Gtk.Widget build_file_tab () {
    var file_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
    file_box.set_margin_top (15);
    file_box.set_margin_bottom (15);
    file_box.set_margin_start (15);
    file_box.set_margin_end (15);

    var file_desc = new Gtk.Label ("Document, media, personal info");
    file_desc.set_xalign (0);

    // --- Category dropdown ---
    var cat_label = new Gtk.Label ("Category:");
    cat_label.set_xalign (0);

    DorkCategory[] categories = get_file_categories ();

    var cat_strings = new string[categories.length];
    for (int i = 0; i < categories.length; i++) {
        cat_strings[i] = categories[i].name;
    }
    var cat_combo = new Gtk.DropDown (new Gtk.StringList (cat_strings), null);

    // --- Filetype preset dropdown ---
    var preset_label = new Gtk.Label ("Filetype Preset:");
    preset_label.set_xalign (0);
    preset_label.set_visible (false);

    var preset_combo = new Gtk.DropDown (new Gtk.StringList ({}), null);
    preset_combo.set_visible (false);

    // --- Domain entry ---
    var domain_entry = new Gtk.Entry ();
    domain_entry.set_placeholder_text ("target.com");

    // --- Manual filetype entry (only for Custom) ---
    var filetype_entry = new Gtk.Entry ();
    filetype_entry.set_placeholder_text ("pdf docx xls  (custom filetypes)");

    // --- Search button ---
    var file_button = new Gtk.Button.with_label ("Search Files");

    cat_combo.notify["selected"].connect (() => {
        uint cat_idx = cat_combo.get_selected ();
        if (cat_idx >= categories.length) return;

        bool is_custom = (categories[cat_idx].name == "Custom");

        filetype_entry.set_visible (is_custom);
        preset_label.set_visible (!is_custom);
        preset_combo.set_visible (!is_custom);

        if (!is_custom) {
            var preset_strings = new string[categories[cat_idx].dorks.length];
            for (int i = 0; i < categories[cat_idx].dorks.length; i++) {
                preset_strings[i] = categories[cat_idx].dorks[i].label;
            }
            preset_combo.set_model (new Gtk.StringList (preset_strings));
            if (categories[cat_idx].dorks.length > 0)
                preset_combo.set_selected (0);
        }
    });

    file_button.clicked.connect (() => {
        string domain = domain_entry.get_text ().strip ();
        uint cat_idx = cat_combo.get_selected ();
        if (cat_idx >= categories.length) return;

        string filetype_part = "";

        if (categories[cat_idx].name == "Custom") {
            string types = filetype_entry.get_text ().strip ();
            if (types == "") return;
            string[] parts = types.split (" ");
            string[] ft_parts = {};
            foreach (var p in parts) {
                if (p.strip () != "")
                    ft_parts += @"filetype:$(p.strip ())";
            }
            filetype_part = string.joinv (" OR ", ft_parts);
        } else {
            uint preset_idx = preset_combo.get_selected ();
            if (preset_idx >= categories[cat_idx].dorks.length) return;
            string raw_types = categories[cat_idx].dorks[preset_idx].value;
            string[] parts = raw_types.split (" OR ");
            string[] ft_parts = {};
            foreach (var p in parts) {
                if (p.strip () != "")
                    ft_parts += @"filetype:$(p.strip ())";
            }
            filetype_part = string.joinv (" OR ", ft_parts);
        }

        string raw_query = domain != "" ? @"site:$domain $filetype_part" : filetype_part;
        string encoded_query = Uri.escape_string (raw_query);
        string final_url = @"https://www.google.com/search?q=$encoded_query";

        try {
            AppInfo.launch_default_for_uri (final_url, null);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    });

    file_box.append (file_desc);
    file_box.append (cat_label);
    file_box.append (cat_combo);
    file_box.append (preset_label);
    file_box.append (preset_combo);
    file_box.append (domain_entry);
    file_box.append (filetype_entry);
    file_box.append (file_button);

    return file_box;
}

// cyber_tab.vala
// UI for the Cyber Intel tab with Category + Dork dropdowns.

public Gtk.Widget build_cyber_tab () {
    var cyber_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
    cyber_box.set_margin_top (15);
    cyber_box.set_margin_bottom (15);
    cyber_box.set_margin_start (15);
    cyber_box.set_margin_end (15);

    var cyber_desc = new Gtk.Label ("Pentesting, Bug Bounty, Red Team");
    cyber_desc.set_xalign (0);

    // --- Category dropdown ---
    var cat_label = new Gtk.Label ("Category:");
    cat_label.set_xalign (0);

    DorkCategory[] categories = get_cyber_categories ();

    var cat_strings = new string[categories.length];
    for (int i = 0; i < categories.length; i++) {
        cat_strings[i] = categories[i].name;
    }
    var cat_model = new Gtk.StringList (cat_strings);
    var cat_combo = new Gtk.DropDown (cat_model, null);

    // --- Dork dropdown ---
    var dork_label = new Gtk.Label ("Dork:");
    dork_label.set_xalign (0);
    dork_label.set_visible (false);

    var dork_combo = new Gtk.DropDown (new Gtk.StringList ({}), null);
    dork_combo.set_visible (false);

    // --- Site entry ---
    var site_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
    var site_label = new Gtk.Label ("site:");
    site_label.set_xalign (0);
    var site_entry = new Gtk.Entry ();
    site_entry.set_placeholder_text ("example.com");
    site_entry.set_hexpand (true);
    site_row.append (site_label);
    site_row.append (site_entry);

    // --- Keyword entry (only for Custom) ---
    var keyword_entry = new Gtk.Entry ();
    keyword_entry.set_placeholder_text ("topic1 topic2  (custom keywords)");

    // --- Execute button ---
    var button = new Gtk.Button.with_label ("Execute Scan");

    cat_combo.notify["selected"].connect (() => {
        uint cat_idx = cat_combo.get_selected ();
        if (cat_idx >= categories.length) return;

        bool is_custom = (categories[cat_idx].name == "Custom");

        keyword_entry.set_visible (is_custom);
        dork_label.set_visible (!is_custom);
        dork_combo.set_visible (!is_custom);

        if (!is_custom) {
            var dork_strings = new string[categories[cat_idx].dorks.length];
            for (int i = 0; i < categories[cat_idx].dorks.length; i++) {
                dork_strings[i] = categories[cat_idx].dorks[i].label;
            }
            dork_combo.set_model (new Gtk.StringList (dork_strings));
            if (categories[cat_idx].dorks.length > 0)
                dork_combo.set_selected (0);
        }
    });

    button.clicked.connect (() => {
        string site = site_entry.get_text ().strip ();
        uint cat_idx = cat_combo.get_selected ();
        if (cat_idx >= categories.length) return;

        string query_part = "";

        if (categories[cat_idx].name == "Custom") {
            string keywords = keyword_entry.get_text ().strip ();
            if (keywords == "") return;
            query_part = @"\"$keywords\"";
        } else {
            uint dork_idx = dork_combo.get_selected ();
            if (dork_idx >= categories[cat_idx].dorks.length) return;
            query_part = categories[cat_idx].dorks[dork_idx].value;
        }

        string raw_query = site != "" ? @"site:$site $query_part" : query_part;
        string encoded_query = Uri.escape_string (raw_query);
        string final_url = @"https://www.google.com/search?q=$encoded_query";

        try {
            AppInfo.launch_default_for_uri (final_url, null);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    });

    cyber_box.append (cyber_desc);
    cyber_box.append (cat_label);
    cyber_box.append (cat_combo);
    cyber_box.append (dork_label);
    cyber_box.append (dork_combo);
    cyber_box.append (site_row);
    cyber_box.append (keyword_entry);
    cyber_box.append (button);

    return cyber_box;
}

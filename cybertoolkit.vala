using Gtk;
using GLib;

class YourApp : Gtk.Application {

    public YourApp () {
        Object (application_id: "com.dorksearch.CyberToolkit");
    }

    protected override void activate () {
        var window = new Gtk.ApplicationWindow (this);
        window.set_title ("Cyber Toolkit — Security Research Tools");
        window.set_default_size (1100, 800);
        window.set_icon_name ("cybertoolkit");

        // =========================
        // Header Bar + Menu
        // =========================

        var header = new Gtk.HeaderBar ();
        window.set_titlebar (header);

        var menu_button = new Gtk.MenuButton ();
        menu_button.set_tooltip_text ("Application information");
        var menu = new Menu ();

        menu.append ("About", "app.about");

        menu_button.set_menu_model (menu);
        header.pack_end (menu_button);

        // About action
        var about_action = new SimpleAction ("about", null);
        about_action.activate.connect (() => {
            var about = new Gtk.AboutDialog ();
            about.set_transient_for (window);
            about.set_modal (true);
            about.set_program_name ("Cyber Toolkit");
            about.set_logo_icon_name ("cybertoolkit");
            about.set_comments (
                "Pentesting, Bug Bounty, Red Team utilities\n" +
                "File reconnaissance & OSINT tools"
            );
            about.set_version ("1.0");
            about.present ();
        });
        add_action (about_action);

        // Quit action
        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            this.quit ();
        });
        add_action (quit_action);

        // =========================
        // Main Layout
        // =========================

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        var stack = new Gtk.Stack ();
        stack.set_transition_type (StackTransitionType.SLIDE_UP_DOWN);
        stack.set_hexpand (true);
        stack.set_vexpand (true);

        var sidebar = new Gtk.StackSidebar ();
        sidebar.set_stack (stack);
        sidebar.set_size_request (240, -1);
        sidebar.set_vexpand (true);

        main_box.set_spacing (8);
        main_box.append (sidebar);
        main_box.append (stack);

        // =========================
        // TAB 1 - CYBER INTEL
        // =========================

        var cyber_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        cyber_box.set_margin_top (15);
        cyber_box.set_margin_bottom (15);
        cyber_box.set_margin_start (15);
        cyber_box.set_margin_end (15);

        var cyber_desc = new Gtk.Label ("Pentesting, Bug Bounty, Red Team");
        cyber_desc.set_xalign (0);

        var site_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        var site_label = new Gtk.Label ("site:");
        site_label.set_xalign (0);
        var site_entry = new Gtk.Entry ();
        site_entry.set_placeholder_text ("example.com");

        site_row.append (site_label);
        site_row.append (site_entry);

        var keyword_entry = new Gtk.Entry ();
        keyword_entry.set_placeholder_text ("topic1 topic2");

        var button = new Gtk.Button.with_label ("Execute Scan");

        button.clicked.connect (() => {
            string site = site_entry.get_text ().strip ();
            string keywords = keyword_entry.get_text ().strip ();

            if (site == "" || keywords == "")
                return;

            string raw_query = @"site:$site \"$keywords\"";
            string encoded_query = Uri.escape_string (raw_query);
            string final_url = @"https://www.google.com/search?q=$encoded_query";

            try {
                AppInfo.launch_default_for_uri (final_url, null);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }
        });

        cyber_box.append (cyber_desc);
        cyber_box.append (site_row);
        cyber_box.append (keyword_entry);
        cyber_box.append (button);

        stack.add_titled (cyber_box, "cyber", "Cyber Intel");

        // =========================
        // TAB 2 - FILE HUNTER
        // =========================

        var file_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        file_box.set_margin_top (15);
        file_box.set_margin_bottom (15);
        file_box.set_margin_start (15);
        file_box.set_margin_end (15);

        var file_desc = new Gtk.Label ("Document, media, personal info");
        file_desc.set_xalign (0);

        var domain_entry = new Gtk.Entry ();
        domain_entry.set_placeholder_text ("target.com");

        var filetype_entry = new Gtk.Entry ();
        filetype_entry.set_placeholder_text ("pdf docx xls");

        var file_button = new Gtk.Button.with_label ("Search Files");

        file_button.clicked.connect (() => {
            string domain = domain_entry.get_text ().strip ();
            string types = filetype_entry.get_text ().strip ();

            if (domain == "" || types == "")
                return;

            string raw_query = @"site:$domain filetype:$types";
            string encoded_query = Uri.escape_string (raw_query);
            string final_url = @"https://www.google.com/search?q=$encoded_query";

            try {
                AppInfo.launch_default_for_uri (final_url, null);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }
        });

        file_box.append (file_desc);
        file_box.append (domain_entry);
        file_box.append (filetype_entry);
        file_box.append (file_button);

        stack.add_titled (file_box, "filehunter", "File Hunter");

        // =========================
        // TAB 3 - LINKS
        // =========================

        var links_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        links_box.set_margin_top (15);
        links_box.set_margin_bottom (15);
        links_box.set_margin_start (15);
        links_box.set_margin_end (15);

        var links_desc = new Gtk.Label ("Useful OSINT & Dorking Resources");
        links_desc.set_xalign (0);

        var dork_link = new Gtk.LinkButton ("https://dorksearch.pro/index.html");
        dork_link.set_label ("DorkSearch Pro - https://dorksearch.pro/index.html");

        links_box.append (links_desc);
        links_box.append (dork_link);


        // Meta Extractor: all analysis happens locally through ExifTool.
        var meta_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        meta_box.set_margin_top (15);
        meta_box.set_margin_bottom (15);
        meta_box.set_margin_start (15);
        meta_box.set_margin_end (15);

        var meta_desc = new Gtk.Label (
            "Choose a file to read its metadata locally. Missing fields appear as '-'.");
        meta_desc.set_wrap (true);
        meta_desc.set_xalign (0);
        meta_box.append (meta_desc);

        var upload_button = new Gtk.Button.with_label ("Choose File…");
        meta_box.append (upload_button);
        var meta_status = new Gtk.Label ("No file selected.");
        meta_status.set_xalign (0);
        meta_status.set_wrap (true);
        meta_status.set_selectable (true);
        meta_box.append (meta_status);

        var results = new Gtk.TextView ();
        results.set_editable (false);
        results.set_cursor_visible (false);
        results.set_monospace (true);
        results.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        var results_scroll = new Gtk.ScrolledWindow ();
        results_scroll.set_vexpand (true);
        results_scroll.set_child (results);
        meta_box.append (results_scroll);

        upload_button.clicked.connect (() => {
            var chooser = new Gtk.FileChooserNative (
                "Select a file to analyze", window, Gtk.FileChooserAction.OPEN,
                "Analyze", "Cancel");
            chooser.response.connect ((response) => {
                if (response == Gtk.ResponseType.ACCEPT) {
                    var selected = chooser.get_file ();
                    string? path = selected != null ? selected.get_path () : null;
                    if (path == null) {
                        meta_status.set_text ("Please select a local file.");
                    } else {
                        upload_button.set_sensitive (false);
                        meta_status.set_text ("Analyzing: " + path);
                        results.buffer.set_text ("");
                        extract_metadata.begin (path, (obj, res) => {
                            try {
                                results.buffer.set_text (extract_metadata.end (res));
                                meta_status.set_text ("File: " + path);
                            } catch (Error e) {
                                meta_status.set_text ("Analysis failed: " + e.message);
                            }
                            upload_button.set_sensitive (true);
                        });
                    }
                }
                chooser.destroy ();
            });
            chooser.show ();
        });

        stack.add_titled (meta_box, "meta-extractor", "Meta Extractor");
        var meta_action = new SimpleAction ("meta-extractor", null);
        meta_action.activate.connect (() => {
            stack.set_visible_child_name ("meta-extractor");
        });
        add_action (meta_action);

        // Emoji Crypt: an educational zero-width marker encoder/decoder.
        var emoji_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        emoji_box.set_margin_top (15); emoji_box.set_margin_bottom (15);
        emoji_box.set_margin_start (15); emoji_box.set_margin_end (15);
        var emoji_title = new Gtk.Label ("Emoji Crypt — Zero Width Marker Encoder");
        emoji_title.set_xalign (0); emoji_title.set_markup ("<b>Emoji Crypt — Zero Width Marker Encoder</b>");
        emoji_box.append (emoji_title);
        var hide_frame = new Gtk.Frame ("INJECT PAYLOAD (HIDE)");
        var hide = new Gtk.Box (Gtk.Orientation.VERTICAL, 6); hide.set_margin_top (8); hide.set_margin_bottom (8); hide.set_margin_start (8); hide.set_margin_end (8);
        var emoji_input = new Gtk.Entry (); emoji_input.set_placeholder_text ("Emoji cover text, e.g. 😀 🌍 🔒");
        var secret_input = new Gtk.Entry (); secret_input.set_placeholder_text ("Secret message");
        var inject = new Gtk.Button.with_label ("Inject data"); var hidden_output = new Gtk.Entry (); hidden_output.set_editable (false);
        hide.append (emoji_input); hide.append (secret_input); hide.append (inject); hide.append (hidden_output); hide_frame.set_child (hide); emoji_box.append (hide_frame);
        var reveal_frame = new Gtk.Frame ("EXTRACT PAYLOAD (REVEAL)");
        var reveal = new Gtk.Box (Gtk.Orientation.VERTICAL, 6); reveal.set_margin_top (8); reveal.set_margin_bottom (8); reveal.set_margin_start (8); reveal.set_margin_end (8);
        var encoded_input = new Gtk.Entry (); encoded_input.set_placeholder_text ("Paste encoded text");
        var analyze = new Gtk.Button.with_label ("Analyze and decrypt"); var revealed_output = new Gtk.Entry (); revealed_output.set_editable (false);
        reveal.append (encoded_input); reveal.append (analyze); reveal.append (revealed_output); reveal_frame.set_child (reveal); emoji_box.append (reveal_frame);
        inject.clicked.connect (() => { hidden_output.set_text (emoji_encode (emoji_input.get_text (), secret_input.get_text ())); });
        analyze.clicked.connect (() => { try { revealed_output.set_text (emoji_decode (encoded_input.get_text ())); } catch (Error e) { revealed_output.set_text ("No valid payload: " + e.message); } });
        var docs = new Gtk.Label ("TECHNICAL DOCUMENTATION\nZero Width Markers\nU+200B Zero Width Space = binary 1\nU+200C Zero Width Non-Joiner = binary 0\nU+200D Zero Width Joiner = payload separator\n\nSecurity implications: hidden data can evade visual review, enable data exfiltration, and complicate forensics. Use only with permission; inspect suspicious text by comparing visible and underlying lengths.");
        docs.set_xalign (0); docs.set_wrap (true); emoji_box.append (docs);
        stack.add_titled (emoji_box, "emoji-crypt", "Emoji Crypt");
        var emoji_action = new SimpleAction ("emoji-crypt", null); emoji_action.activate.connect (() => { stack.set_visible_child_name ("emoji-crypt"); }); add_action (emoji_action);

        // WiFi Map: opens the community map in the default browser. Credentials are not handled.
        var wifi_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        wifi_box.set_margin_top (15); wifi_box.set_margin_bottom (15); wifi_box.set_margin_start (15); wifi_box.set_margin_end (15);
        var wifi_desc = new Gtk.Label ("Community WiFi map data is remote and may contain sensitive credentials. This app does not retrieve or display network keys.");
        wifi_desc.set_wrap (true); wifi_desc.set_xalign (0); wifi_box.append (wifi_desc);
        var wifi_button = new Gtk.Button.with_label ("Open WiFi Map");
        wifi_button.clicked.connect (() => { try { Process.spawn_command_line_async (Path.build_filename (Environment.get_current_dir (), "wifi_map")); } catch (Error e) { wifi_desc.set_text ("Build wifi_map first: " + e.message); } });
        wifi_box.append (wifi_button);
        stack.add_titled (wifi_box, "wifi-map", "WiFi Map");
        var wifi_action = new SimpleAction ("wifi-map", null); wifi_action.activate.connect (() => { stack.set_visible_child_name ("wifi-map"); }); add_action (wifi_action);

        var fingerprint_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        fingerprint_box.set_margin_top (15); fingerprint_box.set_margin_bottom (15);
        fingerprint_box.set_margin_start (15); fingerprint_box.set_margin_end (15);
        var fingerprint_desc = new Gtk.Label ("Run a local browser fingerprint test. Results open in your default browser and are not uploaded.");
        fingerprint_desc.set_wrap (true); fingerprint_desc.set_xalign (0); fingerprint_box.append (fingerprint_desc);
        var browser_choice = new Gtk.DropDown.from_strings ({"System default", "Firefox", "Google Chrome", "Chromium", "Brave", "Microsoft Edge", "Safari", "Custom executable"});
        fingerprint_box.append (new Gtk.Label ("Choose browser:")); fingerprint_box.append (browser_choice);
        var custom_browser = new Gtk.Entry (); custom_browser.set_placeholder_text ("Custom browser command or path"); fingerprint_box.append (custom_browser);
        var fingerprint_button = new Gtk.Button.with_label ("Open Fingerprint Tester"); fingerprint_box.append (fingerprint_button);
        var integrated_button = new Gtk.Button.with_label ("Open with integrated Browser"); fingerprint_box.append (integrated_button);
        stack.add_titled (fingerprint_box, "fingerprint", "Browser Fingerprint Tester");

        var fingerprint_action = new SimpleAction ("fingerprint", null);
        fingerprint_action.activate.connect (() => { try { AppInfo.launch_default_for_uri ("file://" + Path.build_filename (Environment.get_current_dir (), "fingerprint.html"), null); } catch (Error e) { stderr.printf ("Fingerprint tester: %s\n", e.message); } });
        add_action (fingerprint_action);
        integrated_button.clicked.connect (() => { try { Process.spawn_command_line_async ("./integrated_browser " + Shell.quote (Path.build_filename (Environment.get_current_dir (), "fingerprint.html"))); } catch (Error e) { fingerprint_desc.set_text ("Integrated browser unavailable: " + e.message); } });
        fingerprint_button.clicked.connect (() => {
            uint selected = browser_choice.get_selected (); string[] names = {"", "firefox", "google-chrome", "chromium", "brave-browser", "microsoft-edge", "open", custom_browser.get_text ().strip ()};
            string browser = names[selected]; string page = Path.build_filename (Environment.get_current_dir (), "fingerprint.html");
            try {
                if (browser == "") fingerprint_action.activate (null);
                else if (browser == "") fingerprint_desc.set_text ("Enter a custom browser command or choose another browser.");
                else if (browser == "open") Process.spawn_command_line_async ("open " + Shell.quote (page));
                else if (Environment.find_program_in_path (browser) != null) Process.spawn_command_line_async (browser + " " + Shell.quote (page));
                else fingerprint_desc.set_text ("Selected browser is not installed: " + browser);
            } catch (Error e) { fingerprint_desc.set_text ("Could not open browser: " + e.message); }
        });

        var network_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10); network_box.set_margin_top (15); network_box.set_margin_bottom (15); network_box.set_margin_start (15); network_box.set_margin_end (15);
        var network_title = new Gtk.Label ("Network Tests"); network_title.set_xalign (0); network_title.set_markup ("<b>Network Tests</b>"); network_box.append (network_title);
        var ip_frame = new Gtk.Frame ("Public IP lookup"); var ip_inner = new Gtk.Box (Gtk.Orientation.VERTICAL, 8); ip_inner.set_margin_top (8); ip_inner.set_margin_bottom (8); ip_inner.set_margin_start (8); ip_inner.set_margin_end (8);
        var ip_desc = new Gtk.Label ("Shows the public IP address websites see. Sends a request to api.ipify.org."); ip_desc.set_wrap (true); ip_desc.set_xalign (0); ip_inner.append (ip_desc);
        var ip_button = new Gtk.Button.with_label ("CHECK MY IP"); var ip_result = new Gtk.Label ("Public IP seen by websites: ———"); ip_result.set_xalign (0); ip_result.set_selectable (true); ip_inner.append (ip_button); ip_inner.append (ip_result); ip_frame.set_child (ip_inner); network_box.append (ip_frame);
        ip_button.clicked.connect (() => { ip_button.set_sensitive (false); ip_result.set_text ("Looking up…"); lookup_public_ip.begin ((obj,res) => { try { ip_result.set_text ("Public IP seen by websites: " + lookup_public_ip.end (res)); } catch (Error e) { ip_result.set_text ("Lookup failed: " + e.message); } ip_button.set_sensitive (true); }); });
        var rtc_frame = new Gtk.Frame ("WebRTC leak test"); var rtc_inner = new Gtk.Box (Gtk.Orientation.VERTICAL, 8); rtc_inner.set_margin_top (8); rtc_inner.set_margin_bottom (8); rtc_inner.set_margin_start (8); rtc_inner.set_margin_end (8);
        var rtc_desc = new Gtk.Label ("WebRTC is a browser JavaScript API and cannot be queried by native GTK/Vala alone."); rtc_desc.set_wrap (true); rtc_desc.set_xalign (0); rtc_inner.append (rtc_desc); var rtc_button = new Gtk.Button.with_label ("RUN WEBRTC TEST"); var rtc_browser_button = new Gtk.Button.with_label ("Run in integrated browser"); var rtc_result = new Gtk.Label ("Candidates: unavailable in native GTK"); rtc_result.set_xalign (0); rtc_result.set_selectable (true); rtc_inner.append (rtc_button); rtc_inner.append (rtc_browser_button); rtc_inner.append (rtc_result); rtc_frame.set_child (rtc_inner); network_box.append (rtc_frame);
        rtc_browser_button.clicked.connect (() => { try { AppInfo.launch_default_for_uri ("file://" + Path.build_filename (Environment.get_current_dir (), "network_tests.html"), null); } catch (Error e) { rtc_result.set_text ("Unable to open browser test: " + e.message); } });
        
        stack.add_titled (network_box, "network-tests", "Network Tests"); var network_action = new SimpleAction ("network-tests", null); network_action.activate.connect (() => { stack.set_visible_child_name ("network-tests"); }); add_action (network_action);

        var dork_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10); dork_box.set_margin_top (15); dork_box.set_margin_bottom (15); dork_box.set_margin_start (15); dork_box.set_margin_end (15);
        var dork_note = new Gtk.Label ("Google dork builder for authorized security research. Use only on domains you own or are permitted to assess."); dork_note.set_wrap (true); dork_note.set_xalign (0); dork_box.append (dork_note);
        string[] categories = {"Files & Documents", "Server & Config", "Bug Bounty & Vulnerabilities", "Cloud & DevOps", "OSINT & Recon", "Advanced Operators"}; string[] types = {"Public PDFs", "Directory Listing", "Config Files", "Admin Panels", "Swagger APIs", "Subdomains"}; var dork_category = new Gtk.DropDown.from_strings (categories); var dork_type = new Gtk.DropDown.from_strings (types); dork_box.append (new Gtk.Label ("Category")); dork_box.append (dork_category); dork_box.append (new Gtk.Label ("Dork type")); dork_box.append (dork_type);
        var dork_input = new Gtk.Entry (); dork_input.set_placeholder_text ("Optional domain, e.g. example.com"); dork_box.append (dork_input); var dork_example = new Gtk.Label ("Example: filetype:pdf"); dork_example.set_xalign (0); dork_box.append (dork_example); var dork_search = new Gtk.Button.with_label ("Search in Google"); dork_box.append (dork_search);
        dork_type.notify["selected"].connect (() => { string[] examples = {"filetype:pdf", "intitle:index_of", "filetype:xml OR filetype:conf OR filetype:env", "inurl:admin OR inurl:login", "inurl:swagger OR inurl:api-docs", "-www"}; dork_example.set_text ("Example: " + examples[dork_type.get_selected ()]); });
        dork_search.clicked.connect (() => { string[] examples = {"filetype:pdf", "intitle:index_of", "filetype:xml OR filetype:conf OR filetype:env", "inurl:admin OR inurl:login", "inurl:swagger OR inurl:api-docs", "-www"}; string q = examples[dork_type.get_selected ()]; string domain = dork_input.get_text ().strip (); string query = domain != "" ? "site:" + domain + " " + q : q; try { AppInfo.launch_default_for_uri ("https://www.google.com/search?q=" + Uri.escape_string (query), null); } catch (Error e) { dork_note.set_text (e.message); } });
        stack.add_titled (dork_box, "cyber-dorks", "Cyber Dorks"); var dork_action = new SimpleAction ("cyber-dorks", null); dork_action.activate.connect (() => { stack.set_visible_child_name ("cyber-dorks"); }); add_action (dork_action);

        var advanced_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10); advanced_box.set_margin_top (15); advanced_box.set_margin_bottom (15); advanced_box.set_margin_start (15); advanced_box.set_margin_end (15);
        var advanced_note = new Gtk.Label ("Advanced Google dorks for authorized research only. Replace example.com with a domain you own or are permitted to assess."); advanced_note.set_wrap (true); advanced_note.set_xalign (0); advanced_box.append (advanced_note);
        string[] advanced_names = {"Exposed Environment Files", "Public Log Files", "SQL Database Dumps", "Directory Listing", "Config Files (XML/CONF)", "Exposed Git Repositories", "WordPress User Enumeration", "PHP Errors", "Public S3 Buckets", "Login Portals"};
        string[] advanced_queries = {"filetype:env DB_PASSWORD site:example.com", "filetype:log OR filetype:txt intext:password site:example.com", "filetype:sql intext:INSERT INTO site:example.com", "intitle:index of parent directory site:example.com", "filetype:xml OR filetype:conf intext:password site:example.com", "inurl:/.git site:example.com", "inurl:wp-content OR inurl:wp-includes site:example.com", "filetype:php intext:fatal error site:example.com", "site:s3.amazonaws.com company-name", "inurl:login OR inurl:admin OR intitle:login site:example.com"};
        string[] advanced_descriptions = {"Environment files may contain API keys and database settings.", "Logs can expose user data, internal addresses, and paths.", "Public SQL backups may contain schemas and data.", "Directory listings expose files on misconfigured servers.", "Configuration files can reveal versions and internal details.", "A public Git directory can expose repository history.", "WordPress paths can reveal login and author endpoints.", "PHP errors may disclose server filesystem paths.", "Public buckets may contain unintentionally exposed objects.", "Login portals identify authentication entry points."};
        var advanced_select = new Gtk.DropDown.from_strings (advanced_names); advanced_box.append (new Gtk.Label ("Dork type")); advanced_box.append (advanced_select); var advanced_description = new Gtk.Label (advanced_descriptions[0]); advanced_description.set_wrap (true); advanced_description.set_xalign (0); advanced_box.append (advanced_description);
        var advanced_example = new Gtk.Label ("Example query: " + advanced_queries[0]); advanced_example.set_selectable (true); advanced_example.set_wrap (true); advanced_example.set_xalign (0); advanced_box.append (advanced_example);
        advanced_select.notify["selected"].connect (() => { uint n=advanced_select.get_selected (); advanced_description.set_text (advanced_descriptions[n]); advanced_example.set_text ("Example query: " + advanced_queries[n]); });
        var advanced_search = new Gtk.Button.with_label ("Open query in Google"); advanced_box.append (advanced_search); advanced_search.clicked.connect (() => { try { AppInfo.launch_default_for_uri ("https://www.google.com/search?q=" + Uri.escape_string (advanced_queries[advanced_select.get_selected ()]), null); } catch (Error e) { advanced_note.set_text (e.message); } });
        stack.add_titled (advanced_box, "advanced-cyberdorks", "Advanced Cyberdorks"); var advanced_action = new SimpleAction ("advanced-cyberdorks", null); advanced_action.activate.connect (() => { stack.set_visible_child_name ("advanced-cyberdorks"); }); add_action (advanced_action);

        var glossary_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8); glossary_box.set_margin_top (12); glossary_box.set_margin_bottom (12); glossary_box.set_margin_start (12); glossary_box.set_margin_end (12);
        var glossary_title = new Gtk.Label ("Cybersecurity Glossary"); glossary_title.set_xalign (0); glossary_title.set_markup ("<b>Cybersecurity Glossary</b>"); glossary_box.append (glossary_title);
        var glossary_list = new Gtk.ListBox (); glossary_list.set_selection_mode (Gtk.SelectionMode.NONE); glossary_list.set_vexpand (true);
        string[] glossary_items = {"APT|Stealthy long-term unauthorized access.|THREAT_INTEL", "Adware|Software displaying unwanted advertising.|MALWARE", "Air Gap|Physical isolation between networks.|DEFENSE", "AES|Symmetric encryption standard.|CRYPTOGRAPHY", "API|Interface for accessing software services.|DEV", "Backdoor|Bypasses normal access controls.|MALWARE", "Blue Team|Defenders monitoring and improving security.|DEFENSE", "Botnet|Compromised computers controlled as a group.|ATTACK", "DDoS|Traffic flooding that disrupts availability.|ATTACK", "Encryption|Encoding information for authorized access.|CRYPTOGRAPHY", "Exif Data|Metadata embedded in images.|OSINT", "Firewall|Controls network traffic by rules.|DEFENSE", "Hash|One-way function for integrity checks.|CRYPTOGRAPHY", "Malware|Software designed to damage or access systems.|MALWARE", "OSINT|Intelligence from public sources.|OSINT", "Phishing|Fraudulent attempt to obtain sensitive information.|ATTACK", "Ransomware|Malware blocking access or threatening data.|MALWARE", "SQL Injection|Injecting database commands through input.|WEB_VULN", "VPN|Encrypted connection across an untrusted network.|PRIVACY", "XSS|Injecting scripts into pages viewed by users.|WEB_VULN", "Zero-Day|Unknown vulnerability without a vendor fix.|CRITICAL"};
        foreach (string item in glossary_items) { string[] parts=item.split ("|"); var row=new Gtk.Box (Gtk.Orientation.VERTICAL, 3); row.set_margin_top (8); row.set_margin_bottom (8); row.set_margin_start (10); row.set_margin_end (10); var term=new Gtk.Label (parts[0]); term.set_xalign (0); term.set_markup ("<b>" + parts[0] + "</b>"); var desc=new Gtk.Label (parts[1]); desc.set_xalign (0); desc.set_wrap (true); var tag=new Gtk.Label ("#" + parts[2]); tag.set_xalign (0); tag.add_css_class ("dim-label"); row.append (term); row.append (desc); row.append (tag); glossary_list.append (row); }
        var glossary_scroll = new Gtk.ScrolledWindow (); glossary_scroll.set_vexpand (true); glossary_scroll.set_child (glossary_list); glossary_box.append (glossary_scroll);

        stack.add_titled (glossary_box, "glossary", "Glossary");
        stack.add_titled (links_box, "links", "Links"); var glossary_action = new SimpleAction ("glossary", null); glossary_action.activate.connect (() => { stack.set_visible_child_name ("glossary"); }); add_action (glossary_action);

        window.set_child (main_box);
        window.present ();
    }

    private static string emoji_encode (string cover, string secret) {
        var encoded = new StringBuilder (cover);
        encoded.append_unichar ('\u200d');
        for (int i = 0; i < secret.length; i++) {
            uint8 b = (uint8) secret.data[i];
            for (int bit = 7; bit >= 0; bit--)
                encoded.append_unichar (((b >> bit) & 1) == 1 ? '\u200b' : '\u200c');
        }
        return encoded.str;
    }

    private static string emoji_decode (string encoded) throws Error {
        int separator = encoded.index_of_char ('\u200d');
        if (separator < 0) throw new IOError.INVALID_DATA ("Missing payload separator.");
        string payload = encoded.substring (separator + "\u200d".length);
        var bytes = new StringBuilder ();
        int bits = 0; uint8 value = 0;
        for (int i = 0; i < payload.length;) {
            unichar c = payload.get_char (i); i += c.to_string ().length;
            if (c != '\u200b' && c != '\u200c') continue;
            value = (uint8) ((value << 1) | (c == '\u200b' ? 1 : 0)); bits++;
            if (bits == 8) { bytes.append_c ((char) value); bits = 0; value = 0; }
        }
        if (bits != 0) throw new IOError.INVALID_DATA ("Incomplete binary payload.");
        return bytes.str;
    }

    private async string lookup_public_ip () throws Error {
        string[] argv = { "curl", "--fail", "--silent", "--show-error", "https://api.ipify.org" };
        var process = new Subprocess.newv (argv, SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE); string? output; string? errors; yield process.communicate_utf8_async (null, null, out output, out errors); if (!process.get_successful ()) throw new IOError.FAILED (errors ?? "Request failed"); return (output ?? "").strip ();
    }

    private async string extract_metadata (string path) throws Error {
        if (Environment.find_program_in_path ("exiftool") == null) {
            throw new IOError.NOT_FOUND (
                "ExifTool is required. Install libimage-exiftool-perl and try again.");
        }

        // Separate arguments and an absolute path keep filenames out of shell parsing.
        string[] command = {
            "exiftool", "-f", "-a", "-G1", "-s",
            "-Make", "-Model", "-DeviceModelName",
            "-DateTimeOriginal", "-CreateDate", "-ModifyDate", "-OffsetTimeOriginal",
            "-Software", "-OperatingSystem", "-OSVersion",
            "-ExposureTime", "-ExposureProgram", "-ExposureMode",
            "-ExposureCompensation", "-FNumber", "-ISO", "-Warning", "-Error",
            "--", Filename.canonicalize (path)
        };
        var process = new Subprocess.newv (command,
            SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE);
        string? output;
        string? errors;
        yield process.communicate_utf8_async (null, null, out output, out errors);
        if (!process.get_successful ()) {
            throw new IOError.FAILED (
                errors != null && errors.strip () != "" ? errors.strip () :
                "ExifTool could not read this file.");
        }
        return (output ?? "No metadata found.") +
            (errors != null && errors.strip () != "" ? "\n" + errors : "");
    }

    public static int main (string[] args) {
        return new YourApp ().run (args);
    }
}


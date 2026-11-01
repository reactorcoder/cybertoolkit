// links_tab.vala
// UI for the Links tab.

public Gtk.Widget build_links_tab () {
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

    return links_box;
}

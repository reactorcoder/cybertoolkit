// app.vala
// Main application class and window setup.

using Gtk;
using GLib;

class YourApp : Gtk.Application {

    public YourApp () {
        Object (application_id: "com.dorksearch.CyberToolkit");
    }

    protected override void activate () {
        var window = new Gtk.ApplicationWindow (this);
        window.set_title ("Cyber Toolkit");
        window.set_default_size (700, 400);
        window.set_icon_name ("cybertoolkit");

        // Header Bar
        var header = new Gtk.HeaderBar ();
        window.set_titlebar (header);

        var menu_button = new Gtk.MenuButton ();
        var menu = new Menu ();
        menu.append ("About", "app.about");
        menu.append ("Quit", "app.quit");
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
        quit_action.activate.connect (() => { this.quit (); });
        add_action (quit_action);

        // Main layout
        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        var stack = new Gtk.Stack ();
        stack.set_transition_type (StackTransitionType.SLIDE_UP_DOWN);
        stack.set_hexpand (true);
        stack.set_vexpand (true);

        var sidebar = new Gtk.StackSidebar ();
        sidebar.set_stack (stack);
        sidebar.set_size_request (180, -1);

        main_box.append (sidebar);
        main_box.append (stack);

        stack.add_titled (build_cyber_tab (), "cyber", "Cyber Intel");
        stack.add_titled (build_file_tab (), "filehunter", "File Hunter");
        stack.add_titled (build_exif_tab (), "exif", "Exif Metadata");
        stack.add_titled (build_emoji_tab (), "emoji", "Emoji Steganography");
        stack.add_titled (build_subfinder_tab (), "subfinder", "Subfinder");
        stack.add_titled (build_links_tab (), "links", "Links");

        window.set_child (main_box);
        window.present ();
    }

    public static int main (string[] args) {
        return new YourApp ().run (args);
    }
}

using Gtk;
using WebKit;
int main (string[] args) {
    Gtk.init (ref args);
    var w = new Gtk.Window (); w.set_title ("Integrated Browser"); w.set_default_size (1100, 800);
    var v = new WebView (); string page = args.length > 1 ? args[1] : "fingerprint.html";
    v.load_uri ("file://" + page); w.add (v); w.show_all (); Gtk.main (); return 0;
}

// emoji_tab.vala
// Emoji Steganography tab using Zero Width Character encoding.
//
// MECHANISM:
//   Each character of the secret message is converted to 8-bit binary.
//   Binary 1  -> U+200B (Zero Width Space)
//   Binary 0  -> U+200C (Zero Width Non-Joiner)
//   Char sep  -> U+200D (Zero Width Joiner)
//   The invisible sequence is injected between the emojis of the cover text.

const string ZW_ONE = "\xE2\x80\x8B";   // U+200B  Zero Width Space        = bit 1
const string ZW_ZER = "\xE2\x80\x8C";   // U+200C  Zero Width Non-Joiner   = bit 0
const string ZW_SEP = "\xE2\x80\x8D";   // U+200D  Zero Width Joiner       = char separator

private string encode_zw (string secret) {
    var sb = new StringBuilder ();
    for (int i = 0; i < secret.length; i++) {
        if (i > 0) sb.append (ZW_SEP);
        uint8 c = secret.data[i];
        for (int bit = 7; bit >= 0; bit--) {
            if ((c >> bit & 1) == 1)
                sb.append (ZW_ONE);
            else
                sb.append (ZW_ZER);
        }
    }
    return sb.str;
}

private string inject_payload (string cover, string secret) {
    string payload = encode_zw (secret);
    if (cover.length == 0) return payload;
    string first = cover.substring (0, cover.index_of_nth_char (1));
    string rest  = cover.substring (cover.index_of_nth_char (1));
    return first + payload + rest;
}

private string decode_zw (string input) {
    var zw_only = new StringBuilder ();
    int i = 0;
    uint8[] bytes = input.data;

    while (i < bytes.length) {
        if (i + 2 < bytes.length &&
            bytes[i] == 0xE2 && bytes[i+1] == 0x80 &&
            (bytes[i+2] == 0x8B || bytes[i+2] == 0x8C || bytes[i+2] == 0x8D)) {
            if (bytes[i+2] == 0x8B) zw_only.append (ZW_ONE);
            else if (bytes[i+2] == 0x8C) zw_only.append (ZW_ZER);
            else zw_only.append (ZW_SEP);
            i += 3;
        } else {
            i++;
        }
    }

    if (zw_only.len == 0) return "";

    string[] char_groups = zw_only.str.split (ZW_SEP);
    var result = new StringBuilder ();

    foreach (string group in char_groups) {
        if (group.length == 0) continue;
        uint8 val = 0;
        int bit_pos = 7;
        int gi = 0;
        uint8[] gbytes = group.data;

        while (gi < gbytes.length && bit_pos >= 0) {
            if (gi + 2 < gbytes.length &&
                gbytes[gi] == 0xE2 && gbytes[gi+1] == 0x80) {
                if (gbytes[gi+2] == 0x8B) val |= (uint8)(1 << bit_pos);
                bit_pos--;
                gi += 3;
            } else {
                gi++;
            }
        }
        if (val > 0)
            result.append_c ((char)val);
    }

    return result.str;
}

private void copy_to_clipboard (Gtk.Widget widget, string text) {
    var val = GLib.Value (typeof (string));
    val.set_string (text);
    var cp = new Gdk.ContentProvider.for_value (val);
    widget.get_clipboard ().set_content (cp);
}

public Gtk.Widget build_emoji_tab () {
    var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
    box.set_margin_top (15);
    box.set_margin_bottom (15);
    box.set_margin_start (15);
    box.set_margin_end (15);

    var desc = new Gtk.Label ("Zero Width Character Steganography — hide text inside emoji messages");
    desc.set_xalign (0);
    desc.set_wrap (true);

    // =====================
    // INJECT section
    // =====================
    var inject_frame = new Gtk.Frame ("  INJECT PAYLOAD (HIDE)  ");

    var inject_inner = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
    inject_inner.set_margin_top (10);
    inject_inner.set_margin_bottom (10);
    inject_inner.set_margin_start (10);
    inject_inner.set_margin_end (10);

    var cover_label = new Gtk.Label ("Cover text (emojis):");
    cover_label.set_xalign (0);
    var cover_entry = new Gtk.Entry ();
    cover_entry.set_placeholder_text ("🔥💀🕵️ 🌐🔐");

    var secret_label = new Gtk.Label ("Secret message:");
    secret_label.set_xalign (0);
    var secret_entry = new Gtk.Entry ();
    secret_entry.set_placeholder_text ("hidden payload here");

    var inject_btn = new Gtk.Button.with_label ("⬇  INJECT DATA");

    var inject_out_label = new Gtk.Label ("Output (copy this — it contains the hidden payload):");
    inject_out_label.set_xalign (0);
    var inject_out = new Gtk.TextView ();
    inject_out.set_editable (false);
    inject_out.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
    inject_out.set_size_request (-1, 60);

    var copy_btn = new Gtk.Button.with_label ("📋  Copy Encrypted Output");
    copy_btn.set_sensitive (false);

    inject_inner.append (cover_label);
    inject_inner.append (cover_entry);
    inject_inner.append (secret_label);
    inject_inner.append (secret_entry);
    inject_inner.append (inject_btn);
    inject_inner.append (inject_out_label);
    inject_inner.append (inject_out);
    inject_inner.append (copy_btn);
    inject_frame.set_child (inject_inner);

    // =====================
    // EXTRACT section
    // =====================
    var extract_frame = new Gtk.Frame ("  EXTRACT PAYLOAD (REVEAL)  ");

    var extract_inner = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
    extract_inner.set_margin_top (10);
    extract_inner.set_margin_bottom (10);
    extract_inner.set_margin_start (10);
    extract_inner.set_margin_end (10);

    var analyze_label = new Gtk.Label ("Paste suspicious text:");
    analyze_label.set_xalign (0);
    var analyze_in = new Gtk.TextView ();
    analyze_in.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
    analyze_in.set_size_request (-1, 60);

    var extract_btn = new Gtk.Button.with_label ("🔍  ANALYZE & EXTRACT");

    var result_label = new Gtk.Label ("Extracted secret:");
    result_label.set_xalign (0);
    var result_out = new Gtk.TextView ();
    result_out.set_editable (false);
    result_out.set_monospace (true);
    result_out.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
    result_out.set_size_request (-1, 60);

    extract_inner.append (analyze_label);
    extract_inner.append (analyze_in);
    extract_inner.append (extract_btn);
    extract_inner.append (result_label);
    extract_inner.append (result_out);
    extract_frame.set_child (extract_inner);

    // =====================
    // Wire up logic
    // =====================
    inject_btn.clicked.connect (() => {
        string cover  = cover_entry.get_text ();
        string secret = secret_entry.get_text ();
        if (cover == "" || secret == "") return;
        string result = inject_payload (cover, secret);
        inject_out.get_buffer ().set_text (result, -1);
        copy_btn.set_sensitive (true);
    });

    copy_btn.clicked.connect (() => {
        Gtk.TextIter start, end;
        inject_out.get_buffer ().get_bounds (out start, out end);
        string txt = inject_out.get_buffer ().get_text (start, end, false);
        copy_to_clipboard (copy_btn, txt);
    });

    extract_btn.clicked.connect (() => {
        Gtk.TextIter start, end;
        analyze_in.get_buffer ().get_bounds (out start, out end);
        string input = analyze_in.get_buffer ().get_text (start, end, false);

        if (input.strip () == "") {
            result_out.get_buffer ().set_text ("// NO INPUT PROVIDED", -1);
            return;
        }

        string decoded = decode_zw (input);
        if (decoded == "")
            result_out.get_buffer ().set_text ("// NO HIDDEN PAYLOAD FOUND", -1);
        else
            result_out.get_buffer ().set_text (decoded, -1);
    });

    box.append (desc);
    box.append (inject_frame);
    box.append (extract_frame);

    var scroll = new Gtk.ScrolledWindow ();
    scroll.set_vexpand (true);
    scroll.set_hexpand (true);
    scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    scroll.set_child (box);

    return scroll;
}

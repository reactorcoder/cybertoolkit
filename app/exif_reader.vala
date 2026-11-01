// exif_reader.vala
// Pure Vala EXIF parser - reads JPEG/TIFF EXIF binary data.
// No external library required.

public struct ExifData {
    public string device_model;
    public string timestamp;
    public string software;
    public string exposure;
    public string iso;
    public string gps_lat;
    public string gps_lon;
    public bool has_gps;
}

// Read a big-endian uint16 from byte array
private uint16 read_u16_be (uint8[] buf, int offset) {
    return (uint16)((buf[offset] << 8) | buf[offset + 1]);
}

// Read a little-endian uint16
private uint16 read_u16_le (uint8[] buf, int offset) {
    return (uint16)(buf[offset] | (buf[offset + 1] << 8));
}

// Read a big-endian uint32
private uint32 read_u32_be (uint8[] buf, int offset) {
    return (buf[offset] << 24) | (buf[offset+1] << 16) | (buf[offset+2] << 8) | buf[offset+3];
}

// Read a little-endian uint32
private uint32 read_u32_le (uint8[] buf, int offset) {
    return buf[offset] | (buf[offset+1] << 8) | (buf[offset+2] << 16) | (buf[offset+3] << 24);
}

private string read_ascii (uint8[] buf, int offset, int length) {
    var sb = new StringBuilder ();
    for (int i = 0; i < length && offset + i < buf.length; i++) {
        uint8 c = buf[offset + i];
        if (c == 0) break;
        if (c >= 32 && c < 127)
            sb.append_c ((char)c);
    }
    return sb.str.strip ();
}

private string rational_to_string (uint8[] buf, int offset, bool little_endian) {
    uint32 num, den;
    if (little_endian) {
        num = read_u32_le (buf, offset);
        den = read_u32_le (buf, offset + 4);
    } else {
        num = read_u32_be (buf, offset);
        den = read_u32_be (buf, offset + 4);
    }
    if (den == 0) return "0";
    if (num % den == 0) return (num / den).to_string ();
    return @"$num/$den";
}

public ExifData parse_exif (string filepath) {
    ExifData result = ExifData () {
        device_model = "Unknown Device",
        timestamp    = "N/A",
        software     = "N/A",
        exposure     = "---",
        iso          = "---",
        gps_lat      = "",
        gps_lon      = "",
        has_gps      = false
    };

    try {
        uint8[] raw;
        FileUtils.get_data (filepath, out raw);

        if (raw.length < 4) return result;

        // Check JPEG magic
        if (raw[0] != 0xFF || raw[1] != 0xD8) return result;

        // Find APP1 marker (FF E1)
        int pos = 2;
        int exif_start = -1;
        while (pos + 4 < raw.length) {
            if (raw[pos] != 0xFF) break;
            uint8 marker = raw[pos + 1];
            int seg_len = read_u16_be (raw, pos + 2);

            if (marker == 0xE1) {
                // Check for "Exif\0\0"
                if (pos + 10 < raw.length &&
                    raw[pos+4] == 'E' && raw[pos+5] == 'x' &&
                    raw[pos+6] == 'i' && raw[pos+7] == 'f') {
                    exif_start = pos + 10; // skip APP1 header + "Exif\0\0"
                    break;
                }
            }
            pos += 2 + seg_len;
        }

        if (exif_start < 0) return result;

        // Determine byte order
        bool little_endian = (raw[exif_start] == 'I'); // "II" = little endian, "MM" = big endian

        // IFD0 offset
        uint32 ifd_offset;
        if (little_endian)
            ifd_offset = read_u32_le (raw, exif_start + 4);
        else
            ifd_offset = read_u32_be (raw, exif_start + 4);

        int ifd_pos = exif_start + (int)ifd_offset;
        if (ifd_pos + 2 >= raw.length) return result;

        uint16 entry_count;
        if (little_endian)
            entry_count = read_u16_le (raw, ifd_pos);
        else
            entry_count = read_u16_be (raw, ifd_pos);

        int exif_ifd_offset = -1;
        int gps_ifd_offset  = -1;

        // Parse IFD0 entries
        for (int i = 0; i < entry_count; i++) {
            int ep = ifd_pos + 2 + i * 12;
            if (ep + 12 > raw.length) break;

            uint16 tag   = little_endian ? read_u16_le (raw, ep) : read_u16_be (raw, ep);
            uint16 type  = little_endian ? read_u16_le (raw, ep + 2) : read_u16_be (raw, ep + 2);
            uint32 count = little_endian ? read_u32_le (raw, ep + 4) : read_u32_be (raw, ep + 4);
            uint32 voff  = little_endian ? read_u32_le (raw, ep + 8) : read_u32_be (raw, ep + 8);

            switch (tag) {
                case 0x0110: // Model
                    if (type == 2) {
                        int off = (count <= 4) ? (ep + 8) : (exif_start + (int)voff);
                        string v = read_ascii (raw, off, (int)count);
                        if (v != "") result.device_model = v;
                    }
                    break;
                case 0x0131: // Software
                    if (type == 2) {
                        int off = (count <= 4) ? (ep + 8) : (exif_start + (int)voff);
                        string v = read_ascii (raw, off, (int)count);
                        if (v != "") result.software = v;
                    }
                    break;
                case 0x8769: // ExifIFD pointer
                    exif_ifd_offset = exif_start + (int)voff;
                    break;
                case 0x8825: // GPS IFD pointer
                    gps_ifd_offset = exif_start + (int)voff;
                    break;
            }
        }

        // Parse ExifIFD
        if (exif_ifd_offset >= 0 && exif_ifd_offset + 2 < raw.length) {
            uint16 ec = little_endian ? read_u16_le (raw, exif_ifd_offset) : read_u16_be (raw, exif_ifd_offset);
            for (int i = 0; i < ec; i++) {
                int ep = exif_ifd_offset + 2 + i * 12;
                if (ep + 12 > raw.length) break;

                uint16 tag   = little_endian ? read_u16_le (raw, ep) : read_u16_be (raw, ep);
                uint16 type  = little_endian ? read_u16_le (raw, ep + 2) : read_u16_be (raw, ep + 2);
                uint32 count = little_endian ? read_u32_le (raw, ep + 4) : read_u32_be (raw, ep + 4);
                uint32 voff  = little_endian ? read_u32_le (raw, ep + 8) : read_u32_be (raw, ep + 8);

                switch (tag) {
                    case 0x9003: // DateTimeOriginal
                        if (type == 2) {
                            int off = (count <= 4) ? (ep + 8) : (exif_start + (int)voff);
                            string v = read_ascii (raw, off, (int)count);
                            if (v != "") result.timestamp = v;
                        }
                        break;
                    case 0x829A: // ExposureTime
                        if (type == 5) { // RATIONAL
                            int off = exif_start + (int)voff;
                            result.exposure = rational_to_string (raw, off, little_endian) + "s";
                        }
                        break;
                    case 0x8827: // ISOSpeedRatings
                        if (type == 3) { // SHORT
                            uint16 iso_val = little_endian ? read_u16_le (raw, ep + 8) : read_u16_be (raw, ep + 8);
                            result.iso = iso_val.to_string ();
                        }
                        break;
                }
            }
        }

        // Parse GPS IFD
        if (gps_ifd_offset >= 0 && gps_ifd_offset + 2 < raw.length) {
            uint16 gc = little_endian ? read_u16_le (raw, gps_ifd_offset) : read_u16_be (raw, gps_ifd_offset);
            string lat_ref = "N", lon_ref = "E";
            double lat = 0, lon = 0;
            bool got_lat = false, got_lon = false;

            for (int i = 0; i < gc; i++) {
                int ep = gps_ifd_offset + 2 + i * 12;
                if (ep + 12 > raw.length) break;

                uint16 tag   = little_endian ? read_u16_le (raw, ep) : read_u16_be (raw, ep);
                uint16 type  = little_endian ? read_u16_le (raw, ep + 2) : read_u16_be (raw, ep + 2);
                uint32 voff  = little_endian ? read_u32_le (raw, ep + 8) : read_u32_be (raw, ep + 8);

                switch (tag) {
                    case 0x0001: // GPSLatitudeRef
                        lat_ref = read_ascii (raw, ep + 8, 2);
                        break;
                    case 0x0003: // GPSLongitudeRef
                        lon_ref = read_ascii (raw, ep + 8, 2);
                        break;
                    case 0x0002: // GPSLatitude (3 rationals)
                        if (type == 5) {
                            int off = exif_start + (int)voff;
                            double deg  = dms_rational (raw, off,     little_endian);
                            double min  = dms_rational (raw, off + 8, little_endian);
                            double sec  = dms_rational (raw, off + 16, little_endian);
                            lat = deg + min / 60.0 + sec / 3600.0;
                            got_lat = true;
                        }
                        break;
                    case 0x0004: // GPSLongitude
                        if (type == 5) {
                            int off = exif_start + (int)voff;
                            double deg  = dms_rational (raw, off,     little_endian);
                            double min  = dms_rational (raw, off + 8, little_endian);
                            double sec  = dms_rational (raw, off + 16, little_endian);
                            lon = deg + min / 60.0 + sec / 3600.0;
                            got_lon = true;
                        }
                        break;
                }
            }

            if (got_lat && got_lon) {
                result.has_gps = true;
                result.gps_lat = "%.6f°%s".printf (lat, lat_ref);
                result.gps_lon = "%.6f°%s".printf (lon, lon_ref);
            }
        }

    } catch (Error e) {
        stderr.printf ("EXIF parse error: %s\n", e.message);
    }

    return result;
}

private double dms_rational (uint8[] buf, int offset, bool little_endian) {
    uint32 num = little_endian ? read_u32_le (buf, offset)     : read_u32_be (buf, offset);
    uint32 den = little_endian ? read_u32_le (buf, offset + 4) : read_u32_be (buf, offset + 4);
    if (den == 0) return 0.0;
    return (double)num / (double)den;
}

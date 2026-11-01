// dork_data.vala
// Add new categories and dorks here easily.
// Two separate category lists: one for Cyber Intel, one for File Hunter.

public struct DorkEntry {
    public string label;
    public string value;
}

public struct DorkCategory {
    public string name;
    public DorkEntry[] dorks;
}

// ============================================================
// CYBER INTEL CATEGORIES
// ============================================================
public DorkCategory[] get_cyber_categories () {
    return {
        DorkCategory () {
            name = "Custom",
            dorks = {}
        },
        DorkCategory () {
            name = "Attack Surface Mapping",
            dorks = {
                DorkEntry () {
                    label = "Exposed Login Pages",
                    value = "inurl:login OR inurl:signin OR inurl:auth"
                },
                DorkEntry () {
                    label = "Exposed Login Pages",
                    value = "inurl:login OR inurl:signin OR inurl:auth"
                },
                DorkEntry () {
                    label = "Admin areas",
                    value = "inurl:admin OR inurl:dashboard"
                },
                DorkEntry () {
                    label = "Public staging environments",
                    value = "inurl:staging OR inurl:preprod OR inurl:uat"
                },
                DorkEntry () {
                    label = "Status pages",
                    value = "intitle:\"status page\" OR inurl:status"
                },
                DorkEntry () {
                    label = "Subdomain references",
                    value = "intext:\"api.\" OR intext:\"dev.\""
                },
                // DorkEntry () {
                //     label = "Admin Panels",
                //     value = "inurl:admin OR inurl:administrator OR inurl:wp-admin"
                // },
            }
        },
        DorkCategory () {
            name = "Exposed Documents",
            dorks = {
                DorkEntry () {
                    label = "PDF Documents",
                    value = "filetype:pdf"
                },
                DorkEntry () {
                    label = "Spreadsheets",
                    value = "filetype:xls OR filetype:xlsx OR filetype:csv"
                },
            }
        },
        DorkCategory () {
            name = "Custom",
            dorks = {}
        },
        // DorkCategory () {
        //     name = "Vulnerability Research",
        //     dorks = {
        //         DorkEntry () {
        //             label = "Open Redirects",
        //             value = "inurl:redirect= OR inurl:url= OR inurl:return="
        //         },
        //     }
        // },
    };
}

// ============================================================
// FILE HUNTER CATEGORIES
// ============================================================
public DorkCategory[] get_file_categories () {
    return {
        DorkCategory () {
            name = "Custom",
            dorks = {}
        },
        DorkCategory () {
            name = "Office Documents",
            dorks = {
                DorkEntry () {
                    label = "Word Documents",
                    value = "docx OR doc"
                },
                DorkEntry () {
                    label = "Excel Spreadsheets",
                    value = "xlsx OR xls OR csv"
                },
                DorkEntry () {
                    label = "PowerPoint Presentations",
                    value = "pptx OR ppt"
                },
                DorkEntry () {
                    label = "All Office Files",
                    value = "docx OR xlsx OR pptx OR doc OR xls OR ppt"
                },
            }
        },
        DorkCategory () {
            name = "Sensitive Files",
            dorks = {
                DorkEntry () {
                    label = "Config & Env Files",
                    value = "env OR cfg OR ini OR conf"
                },
                DorkEntry () {
                    label = "Database Dumps",
                    value = "sql OR db OR sqlite"
                },
                DorkEntry () {
                    label = "Log Files",
                    value = "log OR txt"
                },
                DorkEntry () {
                    label = "Backup Files",
                    value = "bak OR backup OR old OR zip"
                },
            }
        },
        DorkCategory () {
            name = "Data & Reports",
            dorks = {
                DorkEntry () {
                    label = "PDF Reports",
                    value = "pdf"
                },
                DorkEntry () {
                    label = "JSON / XML Data",
                    value = "json OR xml"
                },
                DorkEntry () {
                    label = "CSV Data Exports",
                    value = "csv"
                },
            }
        },
        // DorkCategory () {
        //     name = "Source Code",
        //     dorks = {
        //         DorkEntry () {
        //             label = "PHP Files",
        //             value = "php"
        //         },
        //         DorkEntry () {
        //             label = "Python Scripts",
        //             value = "py"
        //         },
        //     }
        // },
    };
}

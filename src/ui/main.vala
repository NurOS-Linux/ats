using Gtk;
using GLib;

[CCode (cheader_filename = "info.h")]
extern string get_os_name();
extern string get_os_info();
extern string get_kernel_info();
extern string get_cpu_detailed_info();
extern string get_memory_info();
extern string get_gpu_info();
extern string get_uptime_info();
extern string get_storage_info();
extern string get_serial_number();
extern string get_hostname();

// Define the _() function for translations using gettext (not dgettext)
[CCode (cname = "gettext", cheader_filename = "libintl.h")]
extern unowned string _(string msgid);

[CCode (cname = "bindtextdomain", cheader_filename = "libintl.h")]
extern unowned string bindtextdomain(string domainname, string dirname);

[CCode (cname = "textdomain", cheader_filename = "libintl.h")]
extern unowned string textdomain(string domainname);

[CCode (cname = "bind_textdomain_codeset", cheader_filename = "libintl.h")]
extern unowned string bind_textdomain_codeset(string domainname, string codeset);

public class GUIFetch : Adw.Application {
    private Adw.ApplicationWindow window;
    private Adw.HeaderBar header_bar;
    private Gtk.Box main_content;
    private Gtk.Box info_container;
    private Gtk.Image logo_image;
    
    public GUIFetch() {
        Object(application_id: "io.github.realbxnnie.Guifetch");
        
        // Initialize gettext
        Intl.setlocale();
        bindtextdomain("guifetch", Config.LOCALEDIR);
        bind_textdomain_codeset("guifetch", "UTF-8");
        textdomain("guifetch");
    }
    
    protected override void activate() {
        window = new Adw.ApplicationWindow(this);
        window.set_title(_("About This PC"));
        window.set_default_size(530, 650);
        window.set_resizable(false);

        setup_ui();
        load_system_info();
        
        window.present();
    }
    
    private void setup_ui() {
        // Header bar (minimal, like macOS)
        header_bar = new Adw.HeaderBar();
        header_bar.set_show_end_title_buttons(true);
        header_bar.set_show_start_title_buttons(true);
        header_bar.set_title_widget(new Gtk.Label("About This PC"));
        header_bar.add_css_class("flat");
        
        // Main content container
        main_content = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_content.set_spacing(0);
        
        // Create the layout
        create_header_section();
        create_info_section();
        
        // Wrap in scrolled window
        var scrolled = new Gtk.ScrolledWindow();
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scrolled.set_child(main_content);
        
        // Clamp for better proportions
        var clamp = new Adw.Clamp();
        clamp.set_maximum_size(580);
        clamp.set_child(scrolled);
        
        // Toolbar view
        var toolbar_view = new Adw.ToolbarView();
        toolbar_view.add_top_bar(header_bar);
        toolbar_view.set_content(clamp);
        
        window.set_content(toolbar_view);
    }
    
    private void create_header_section() {
        // Header with logo and OS info
        var header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);
        header_box.set_margin_top(40);
        header_box.set_margin_bottom(32);
        header_box.set_margin_start(40);
        header_box.set_margin_end(40);
        header_box.set_halign(Gtk.Align.CENTER);
        
        // Logo
        logo_image = new Gtk.Image();
        logo_image.set_pixel_size(64);
        logo_image.set_halign(Gtk.Align.CENTER);
        logo_image.set_valign(Gtk.Align.CENTER);
        load_embedded_logo();
        
        // OS info box
        var os_info_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
        os_info_box.set_halign(Gtk.Align.CENTER);
        os_info_box.set_valign(Gtk.Align.CENTER);
        
        // OS name
        var os_label = new Gtk.Label(null);
        os_label.set_halign(Gtk.Align.CENTER);
        os_label.add_css_class("title-1");
        os_label.set_markup("<span size='x-large' weight='bold'>%s</span>".printf(get_os_info()));
        
        // Kernel info
        var kernel_label = new Gtk.Label(get_kernel_info());
        kernel_label.set_halign(Gtk.Align.START);
        kernel_label.add_css_class("body");
        kernel_label.add_css_class("dim-label");
        
        // Computer name
        var hostname_label = new Gtk.Label(get_hostname());
        hostname_label.set_halign(Gtk.Align.START);
        hostname_label.add_css_class("caption");
        hostname_label.add_css_class("dim-label");
        
        os_info_box.append(os_label);
        os_info_box.append(kernel_label);
        os_info_box.append(hostname_label);
        
        header_box.append(logo_image);
        header_box.append(os_info_box);
        main_content.append(header_box);
    }
    
private void load_embedded_logo() {
    string distro_logo = "linux.svg";
    
    try {
        string os_release;
        FileUtils.get_contents("/etc/os-release", out os_release);
        
        foreach (string line in os_release.split("\n")) {
            if (line.has_prefix("ID=")) {  
                string distro_id = line.split("=")[1].replace("\"", "").strip().down();
                switch (distro_id) {
                    case "arch":
                        distro_logo = "arch.svg";
                        break;
                    case "ubuntu":
                    case "pop":
                        distro_logo = "ubuntu.svg";
                        break;
                    case "fedora":
                        distro_logo = "fedora.svg";
                        break;
                    case "debian":
                        distro_logo = "debian.svg";
                        break;
                    case "linuxmint":
                        distro_logo = "mint.svg";
                        break;
                    case "gentoo":
                        distro_logo = "gentoo.svg";
                        break;
                    case "nuros":
                        distro_logo = "nuros.svg";
                        break;
                }
                break; // Stop after finding ID
            }
        }
    } catch (Error e) {
        warning("OS detection failed: %s", e.message);
    }
    
    string[] try_paths = {
        "/org/guifetch/%s".printf(distro_logo),
        "/org/guifetch/linux.svg"
    };
    
    foreach (string path in try_paths) {
        try {
            logo_image.set_from_resource(path);
            return; // Success
        } catch (Error e) {
            continue; // Try next path
        }
    }
    
}
    
    private void create_info_section() {
        // Information card
        var card = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        card.add_css_class("card");
        card.set_margin_start(40);
        card.set_margin_end(40);
        card.set_margin_bottom(40);
        
        // Grid container for information
        info_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);
        info_container.set_margin_top(20);
        info_container.set_margin_bottom(20);
        info_container.set_margin_start(24);
        info_container.set_margin_end(24);
        
        card.append(info_container);
        main_content.append(card);
    }
    
    private void load_system_info() {
        // Add detailed system information
        create_info_row(_("Processor"), get_cpu_detailed_info());
        add_separator();
        create_info_row(_("Memory"), get_memory_info());
        add_separator();
        create_info_row(_("Graphics"), get_gpu_info());
        add_separator();
        create_info_row(_("Uptime"), get_uptime_info());
        add_separator();
        create_info_row(_("Storage"), get_storage_info());
        
        // Add serial number if available
        string serial = get_serial_number();
        if (serial != "Unknown" && serial != "") {
            add_separator();
            create_info_row(_("Serial Number"), serial);
        }
    }
    
    private void create_info_row(string label, string value) {
        var row_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        row_box.set_margin_top(12);
        row_box.set_margin_bottom(12);
        
        // Label (left side, consistent width)
        var label_widget = new Gtk.Label(null);
        label_widget.set_xalign(0);
        label_widget.set_size_request(120, -1);
        label_widget.add_css_class("body");
        label_widget.set_valign(Gtk.Align.CENTER);
        label_widget.set_markup("<span size='x-large' weight='bold'>%s</span>".printf(label));
        label_widget.set_halign(Gtk.Align.CENTER);
        
        // Value (right side, expandable)
        var value_widget = new Gtk.Label(value);
        value_widget.set_xalign(0);
        value_widget.set_hexpand(true);
        value_widget.set_wrap(true);
        value_widget.set_wrap_mode(Pango.WrapMode.WORD_CHAR);
        value_widget.set_selectable(true);
        value_widget.add_css_class("body");
        value_widget.opacity = 0.5;
        value_widget.set_valign(Gtk.Align.CENTER);
        
        row_box.append(label_widget);
        row_box.append(value_widget);
        
        info_container.append(row_box);
    }
    
    private void add_separator() {
        var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        separator.set_margin_top(6);
        separator.set_margin_bottom(6);
        separator.add_css_class("spacer");
        info_container.append(separator);
    }
    
    public static int main(string[] args) {
        var app = new GUIFetch();
        return app.run(args);
    }
}
using Gtk;
using Adw;
using GLib;
using ATS;

[CCode (cheader_filename = "info.h")]
extern string get_os_name();
extern string get_os_info();
extern string get_kernel_info();
extern string get_cpu_detailed_info();
extern string get_memory_info();
extern string get_gpu_info();
extern string get_display_info();
extern string get_uptime_info();
extern string get_storage_info();
extern string get_serial_number();
extern string get_hostname();

[CCode (cname = "gettext", cheader_filename = "libintl.h")]
extern unowned string _(string msgid);

[CCode (cname = "bindtextdomain", cheader_filename = "libintl.h")]
extern unowned string bindtextdomain(string domainname, string dirname);

[CCode (cname = "textdomain", cheader_filename = "libintl.h")]
extern unowned string textdomain(string domainname);

[CCode (cname = "bind_textdomain_codeset", cheader_filename = "libintl.h")]
extern unowned string bind_textdomain_codeset(string domainname, string codeset);

// ------------------------
// Main Application Class
// ------------------------
public class ATSApplication : Adw.Application {
    private Adw.ApplicationWindow window;
    private Adw.HeaderBar header_bar;
    private Gtk.Box main_content;
    private Gtk.Box info_container;
    private Gtk.Image logo_image;

    private static string? forced_distro = null;

    public ATSApplication() {
        Object(application_id: "org.nuros.AboutThisSystem");

        // Initialize gettext
        Intl.setlocale();
        bindtextdomain("ats", Config.LOCALEDIR);
        bind_textdomain_codeset("ats", "UTF-8");
        textdomain("ats");
    }

    protected override void activate() {
        window = new Adw.ApplicationWindow(this);
        window.set_title(_("About This System"));
        window.set_default_size(900, 650);
        window.set_resizable(false);

        Logotypes.init();

        setup_ui();
        setup_actions();      // setup About action
        load_system_info();

        window.present();
    }

    private void setup_ui() {
        // Header bar
        header_bar = new Adw.HeaderBar();
        header_bar.set_show_end_title_buttons(true);
        header_bar.set_show_start_title_buttons(true);
        header_bar.set_title_widget(new Gtk.Label(_("About This System")));
        header_bar.add_css_class("flat");

        setup_burger_menu(); // burger menu

        // Main content container
        main_content = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);
        main_content.set_spacing(20);
        main_content.set_margin_top(20);
        main_content.set_margin_bottom(20);
        main_content.set_margin_start(20);
        main_content.set_margin_end(20);

        create_header_section();
        create_info_section();

        var scrolled = new Gtk.ScrolledWindow();
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled.set_child(main_content);

        var clamp = new Adw.Clamp();
        clamp.set_maximum_size(1000);
        clamp.set_child(scrolled);

        var toolbar_view = new Adw.ToolbarView();
        toolbar_view.add_top_bar(header_bar);
        toolbar_view.set_content(clamp);

        window.set_content(toolbar_view);
    }

    // ------------------------
    // Burger menu
    // ------------------------
    private void setup_burger_menu() {
        var menu_button = new Gtk.MenuButton();
        menu_button.add_css_class("flat");
        menu_button.set_icon_name("open-menu-symbolic");
        menu_button.set_halign(Gtk.Align.END);

        var menu_model = new GLib.Menu();
        menu_model.append(_("About"), "app.about");
        menu_button.set_menu_model(menu_model);

        header_bar.pack_end(menu_button);
    }

    // ------------------------
    // Actions
    // ------------------------
    private void setup_actions() {
        var about_action = new SimpleAction("about", null); // pass null
        about_action.activate.connect(() => {
            show_about_dialog();
        });
        add_action(about_action);
    }

    // ------------------------
    // About dialog
    // ------------------------
    private void show_about_dialog() {
    // Create the AboutDialog
    var about = new Gtk.AboutDialog();

    // Make it transient for the main window
    about.set_transient_for(window);
    about.set_modal(true);

    // Set project info from Config namespace
    about.set_program_name(Config.PROJECT_PRETTY_NAME);
    about.set_version(Config.PROJECT_VERSION);
    about.set_comments(Config.PROJECT_DESCRIPTION);
    about.set_website(Config.PROJECT_WEBSITE);

    // Set an icon from the icon theme
    about.set_logo_icon_name("preferences-devices-cpu");

    // Show the dialog
    about.present();
}


    private void create_header_section() {
        var header_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 20);
        header_box.set_halign(Gtk.Align.START);
        header_box.set_valign(Gtk.Align.CENTER);

        logo_image = new Gtk.Image();
        logo_image.set_pixel_size(96);
        logo_image.set_halign(Gtk.Align.CENTER);
        logo_image.set_valign(Gtk.Align.CENTER);
        load_embedded_logo();

        var os_info_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
        os_info_box.set_halign(Gtk.Align.CENTER);
        os_info_box.set_valign(Gtk.Align.CENTER);

        var os_label = new Gtk.Label("<span size='x-large' weight='bold'>%s</span>".printf(get_os_info()));
        os_label.set_use_markup(true);
        os_label.set_halign(Gtk.Align.CENTER);

        var kernel_label = new Gtk.Label(get_kernel_info());
        kernel_label.set_halign(Gtk.Align.CENTER);
        kernel_label.add_css_class("dim-label");

        var hostname_label = new Gtk.Label(get_hostname());
        hostname_label.set_halign(Gtk.Align.CENTER);
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

        if (forced_distro != null) {
            distro_logo = Logotypes.get(forced_distro, "");
        } else {
            try {
                string os_release;
                FileUtils.get_contents("/etc/os-release", out os_release);

                string distro_id = "";
                string distro_id_like = "";

                foreach (string line in os_release.split("\n")) {
                    if (line.has_prefix("ID=")) {
                        distro_id = line.substring(3).replace("\"", "").strip();
                    } else if (line.has_prefix("ID_LIKE=")) {
                        distro_id_like = line.substring(8).replace("\"", "").strip();
                    }
                }

                if (distro_id != "") {
                    distro_logo = Logotypes.get(distro_id, distro_id_like);
                }

            } catch (Error e) {
                warning("OS detection failed: %s", e.message);
            }
        }

        logo_image.set_from_resource("/org/ats/%s".printf(distro_logo));
    }

    private void create_info_section() {
        var card = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        card.add_css_class("card");
        card.set_margin_start(40);
        card.set_margin_end(40);
        card.set_margin_bottom(40);

        info_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);
        info_container.set_margin_top(20);
        info_container.set_margin_bottom(20);
        info_container.set_margin_start(24);
        info_container.set_margin_end(24);

        card.append(info_container);
        main_content.append(card);
    }

    private void load_system_info() {
        create_info_row(_("Processor"), get_cpu_detailed_info());
        add_separator();
        create_info_row(_("Memory"), get_memory_info());
        add_separator();
        create_info_row(_("Graphics"), get_gpu_info());
        add_separator();
        create_info_row(_("Display"), get_display_info());
        add_separator();
        create_info_row(_("Uptime"), get_uptime_info());
        add_separator();
        create_info_row(_("Storage"), get_storage_info());

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

        var label_widget = new Gtk.Label(null);
        label_widget.set_xalign(0);
        label_widget.set_size_request(120, -1);
        label_widget.add_css_class("body");
        label_widget.set_valign(Gtk.Align.CENTER);
        label_widget.set_markup("<span size='large' weight='bold'>%s</span>".printf(label));
        label_widget.set_halign(Gtk.Align.CENTER);

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
        string? distro_opt = null;

        OptionEntry[] entries = {
            { "distro", 'd', 0, OptionArg.STRING, ref distro_opt, "Override detected distro", "DISTRO" },
            { null }
        };

        try {
            var opt_context = new OptionContext("- About This System");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(entries, null);
            opt_context.parse(ref args);
        } catch (OptionError e) {
            stderr.printf("Option parsing failed: %s\n", e.message);
            return 1;
        }

        if (distro_opt != null) {
            forced_distro = distro_opt.strip().down();
        }

        var app = new ATSApplication();
        return app.run(args);
    }
}

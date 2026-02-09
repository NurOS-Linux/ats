using Gee;

namespace ATS {
    public class Logotypes {
        public static HashMap<string, string> DISTRO_LOGOS;

        public static void init() {
            DISTRO_LOGOS = new HashMap<string, string>();
            DISTRO_LOGOS.set("arch", "arch.svg");
            DISTRO_LOGOS.set("ubuntu", "ubuntu.svg");
            DISTRO_LOGOS.set("pop", "pop.svg");
            DISTRO_LOGOS.set("manjaro", "manjaro.svg");
            DISTRO_LOGOS.set("artix", "artix.svg");
            DISTRO_LOGOS.set("arco", "arco.svg");
            DISTRO_LOGOS.set("endeavour", "evour.svg");
            DISTRO_LOGOS.set("garuda", "garuda.svg");
            DISTRO_LOGOS.set("asahi", "asahi.svg");
            DISTRO_LOGOS.set("cachy", "cachyos.svg");
            DISTRO_LOGOS.set("fedora", "fedora.svg");
            DISTRO_LOGOS.set("debian", "debian.svg");
            DISTRO_LOGOS.set("linuxmint", "mint.svg");
            DISTRO_LOGOS.set("gentoo", "gentoo.svg");
            DISTRO_LOGOS.set("nuros", "nuros.svg");
            DISTRO_LOGOS.set("exherbo", "exherbo.svg");
            DISTRO_LOGOS.set("elementary", "elementary.svg");
            DISTRO_LOGOS.set("void", "void.svg");
            DISTRO_LOGOS.set("neon", "kdeneon.svg");
            DISTRO_LOGOS.set("kde-neon", "kdeneon.svg");
            DISTRO_LOGOS.set("KDE Neon", "kdeneon.svg");

            // if you want to transform ur linux desktop into a mac LOL
            DISTRO_LOGOS.set("macos", "macos.svg");
            DISTRO_LOGOS.set("apple", "macos.svg");
        }

        public static string get(string distro_id, string distro_id_like) {
            message("Searching logo for distro_id: '%s'", distro_id); 
            foreach (var entry in DISTRO_LOGOS.entries) {
                message("Current entry: {\n'key': '%s',\n'value': '%s'\n}", entry.key, entry.value); 
                if (distro_id.down().contains(entry.key)) {
                    message(" Found the logotype! {\n'key': '%s',\n'value': '%s'\n}".printf(entry.key, entry.value));
                    return entry.value;
                }
            }
            if (distro_id_like != null || distro_id_like != "") {
                message("Logotype not found. Search logo for distro_id_like: '%s'", distro_id_like);
                foreach (var entry in DISTRO_LOGOS.entries) {
                    message("Current entry: {\n'key': '%s',\n'value': '%s'\n}", entry.key, entry.value); 
                    if (distro_id_like.down().contains(entry.key)) {
                        message(" Found the logotype! {\n'key': '%s',\n'value': '%s'\n}".printf(entry.key, entry.value));
                        return entry.value;
                    }   
                }
            }
            
            message("Logotype not found. The distro ID is probably incorrect. Returning Tux");
            return "linux.svg";
        }
    }
}
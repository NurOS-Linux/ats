# Sources
sources = [
    'ui/main.vala',
    'info.c',
    guifetch_resources  # Available from parent scope
]

# Include directories
include_dirs = include_directories('.')

# Create executable
executable(
    project_name,
    sources,
    dependencies: [gtk4_dep, adwaita_dep, glib_dep, gio_dep, math_dep],
    include_directories: include_dirs,
    vala_args: vala_args,
    c_args: c_args,
    link_args: link_args,
    install: true,
    install_dir: get_option('bindir')
)
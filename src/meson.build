# Import gnome module for resources
gnome = import('gnome')

# Resources
resources = gnome.compile_resources(
    'guifetch-resources',
    'guifetch.gresource.xml',
    source_dir: meson.current_source_dir(),
    c_name: 'guifetch'
)

# Sources
sources = [
    'main.vala',
    'info.c',
    resources
]

# Create executable
executable(
    project_name,
    sources,
    dependencies: [gtk4_dep, adwaita_dep, glib_dep, gio_dep, math_dep],
    vala_args: vala_args,
    c_args: c_args,
    link_args: link_args,
    install: true,
    install_dir: get_option('bindir')
)

# Desktop file
desktop_file_in = configure_file(
    input: 'guifetch.desktop.in',
    output: 'guifetch.desktop',
    configuration: {
        'bindir': get_option('prefix') / get_option('bindir'),
        'project_id': project_id,
        'project_name': project_name
    }
)

# Install desktop file
install_data(
    desktop_file_in,
    install_dir: get_option('datadir') / 'applications',
    rename: '@0@.desktop'.format(project_id)
)

# Install icon (if you have one)
# install_data(
#     'guifetch.svg',
#     install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps',
#     rename: '@0@.svg'.format(project_id)
# )
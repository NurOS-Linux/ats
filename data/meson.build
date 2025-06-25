# Import gnome module for resources
gnome = import('gnome')

# Resources
guifetch_resources = gnome.compile_resources(
    'guifetch-resources',
    'guifetch.gresource.xml',
    source_dir: meson.current_source_dir(),
    c_name: 'guifetch'
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

# Install icon (SVG)
install_data(
    'linux.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps',
    rename: '@0@.svg'.format(project_id)
)
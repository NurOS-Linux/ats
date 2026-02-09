# Import gnome module for resources
gnome = import('gnome')

# Resources
ats_resources = gnome.compile_resources(
    'ats-resources',
    'ats.gresource.xml',
    source_dir: meson.current_source_dir(),
    c_name: 'ats'
)

# Desktop file
desktop_file_in = configure_file(
    input: 'ats.desktop.in',
    output: 'ats.desktop',
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
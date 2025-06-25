project('guifetch', 'vala', 'c',
    version: '0.1.0',
    license: 'GPL-3.0-or-later',
    meson_version: '>= 0.59.0',
    default_options: [
        'warning_level=2',
        'werror=false',
        'c_std=c11',
    ]
)

# Project information
project_name = meson.project_name()
project_version = meson.project_version()
project_id = 'org.guifetch.app'

# Add project root to include directories
project_source_root = meson.current_source_dir()
project_build_root = meson.current_build_dir()

# Configuration data
config_data = configuration_data()
config_data.set_quoted('PROJECT_NAME', project_name)
config_data.set_quoted('PROJECT_VERSION', project_version)
config_data.set_quoted('PROJECT_ID', project_id)
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('DATADIR', get_option('prefix') / get_option('datadir'))

# Dependencies
gtk4_dep = dependency('gtk4', version: '>= 4.6')
adwaita_dep = dependency('libadwaita-1', version: '>= 1.2')
glib_dep = dependency('glib-2.0', version: '>= 2.70')
gio_dep = dependency('gio-2.0')
math_dep = meson.get_compiler('c').find_library('m', required: false)

# Optional libcpuid dependency
libcpuid_found = false
c_args = []
link_args = []

cc = meson.get_compiler('c')
if cc.has_header('libcpuid/libcpuid.h') and cc.find_library('cpuid', required: false).found()
    c_args += ['-DHAVE_LIBCPUID']
    link_args += ['-lcpuid']
    libcpuid_found = true
    message('Building with libcpuid support')
else 
    message('Building without libcpuid support - install libcpuid-dev for enhanced CPU information')
endif

# Vala compiler arguments
vala_args = [
    '--pkg=gtk4',
    '--pkg=libadwaita-1',
    '--pkg=glib-2.0',
    '--pkg=gio-2.0',
    '--target-glib=2.70',
    '--gresources=' + project_source_root / 'src' / 'guifetch.gresource.xml'
]

# Global arguments
add_global_arguments(c_args, language: 'c')

# Import modules
gnome = import('gnome')
i18n = import('i18n')

# Include subdirectories
subdir('src')

# Summary
summary({
    'Project': project_name,
    'Version': project_version,
    'Prefix': get_option('prefix'),
    'Bindir': get_option('prefix') / get_option('bindir'),
    'Datadir': get_option('prefix') / get_option('datadir'),
}, section: 'Directories')

summary({
    'GTK4': gtk4_dep.version(),
    'libadwaita': adwaita_dep.version(),
    'GLib': glib_dep.version(),
    'libcpuid': libcpuid_found ? 'Yes' : 'No (optional)',
}, section: 'Dependencies')

summary({
    'C compiler': cc.get_id(),
    'C standard': get_option('c_std'),
    'Warning level': get_option('warning_level'),
}, section: 'Build options')
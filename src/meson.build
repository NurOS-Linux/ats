project('guifetch', 'vala', 'c',
    version: '0.1.0',
    license: 'GPL-3.0',
    meson_version: '>= 0.59.0'
)

# Import gnome module for resources
gnome = import('gnome')

# Dependencies
gtk4_dep = dependency('gtk4', version: '>= 4.6')
adwaita_dep = dependency('libadwaita-1', version: '>= 1.2')
glib_dep = dependency('glib-2.0', version: '>= 2.70')
gio_dep = dependency('gio-2.0')
math_dep = meson.get_compiler('c').find_library('m', required: false)

# Optional libcpuid dependency (C only, not for Vala)
libcpuid_found = false
c_args = []
vala_args = ['--pkg=gtk4', '--pkg=libadwaita-1', '--pkg=glib-2.0', '--pkg=gio-2.0']
link_args = []

# Try to find libcpuid manually without adding to dependencies
cc = meson.get_compiler('c')
if cc.has_header('libcpuid/libcpuid.h') and cc.find_library('cpuid', required: false).found()
    c_args += ['-DHAVE_LIBCPUID']
    link_args += ['-lcpuid']
    libcpuid_found = true
    message('Building with libcpuid support')
else 
    message('Building without libcpuid support')
endif

# Resources
resources = gnome.compile_resources(
    'guifetch-resources',
    'guifetch.gresource.xml',
    source_dir: '.'
)

# Sources
sources = [
    'main.vala',
    'info.c',
    resources
]

# Create executable without libcpuid in dependencies
executable(
    'guifetch',
    sources,
    dependencies: [gtk4_dep, adwaita_dep, glib_dep, gio_dep, math_dep],
    vala_args: vala_args,
    c_args: c_args,
    link_args: link_args,
    install: true,
    install_dir: get_option('bindir')
)

# Install desktop file
desktop_file = configure_file(
    input: 'guifetch.desktop.in',
    output: 'guifetch.desktop',
    configuration: {
        'bindir': get_option('prefix') / get_option('bindir')
    }
)

install_data(
    desktop_file,
    install_dir: get_option('datadir') / 'applications'
)
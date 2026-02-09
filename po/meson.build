i18n = import('i18n')

# Generate pot file
i18n.gettext(
    project_name,
    preset: 'glib',
    args: [
        '--package-name=' + project_name,
        '--package-version=' + project_version,
        '--msgid-bugs-address=https://github.com/nuros-linux/ats/issues'
    ]
)
#!/bin/bash

DIST_ID=$(lsb_release -i | cut -d: -f2 | sed 's/[[:blank:]]//g' | tr '[:upper:]' '[:lower:]')
DIST_VER=$(lsb_release -r | cut -d: -f2 | sed 's/[[:blank:]]//g')
TEMPLATE_FILES=()
USER_FILES=()


function show_help() {
    cat >&2 <<EOF
$0 --user-file FILENAME --template-file FILE
Installs toolchains based on a template and/or user defined yaml file, template files are applied first then user files are applied.
Required:
    -f FILENAME --user-file FILENAME
        Name of user defined install schema 
Optional
    -t FILE --template-file FILE
        Path to template file to initialize before running a user defined install schema
    -o DISTRO --dist-override DISTRO
        Override which distribution that packages get installed for
EOF
    exit 1
}

while [ "$#" -gt 0 ]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -f|--user-file)
            USER_FILES+=("$2")
            shift 2
            ;;
        -t|--template-file)
            TEMPLATE_FILES+=("$2")
            shift 2
            ;;
        -o|--dist-override)
            DIST_ID=$2
            shift 2
            ;;
        -k|--version-verride)
            DIST_VER=$2
            shift 2
            ;;
        *)
            echo "ERROR: Invalid option $1 provided." >&2
            show_help
            ;;
    esac
done

### from https://unix.stackexchange.com/posts/6348/revisions

# if [ -f /etc/os-release ]; then
#     # freedesktop.org and systemd
#     . /etc/os-release
#     OS=$NAME
#     VER=$VERSION_ID
# elif type lsb_release >/dev/null 2>&1; then
#     # linuxbase.org
#     OS=$(lsb_release -si)
#     VER=$(lsb_release -sr)
# elif [ -f /etc/lsb-release ]; then
#     # For some versions of Debian/Ubuntu without lsb_release command
#     . /etc/lsb-release
#     OS=$DISTRIB_ID
#     VER=$DISTRIB_RELEASE
# elif [ -f /etc/debian_version ]; then
#     # Older Debian/Ubuntu/etc.
#     OS=Debian
#     VER=$(cat /etc/debian_version)
# elif [ -f /etc/SuSe-release ]; then
#     # Older SuSE/etc.
#     ...
# elif [ -f /etc/redhat-release ]; then
#     # Older Red Hat, CentOS, etc.
#     ...
# else
#     # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
#     OS=$(uname -s)
#     VER=$(uname -r)
# fi





./required/$DIST_ID-prereqs.sh

for file in ${TEMPLATE_FILES[@]}
do
    echo -e "### installing toolset for: ${file} ###"
    TOOLS_ARRAY=($(yq -r templates/${file} | grep -v '^ .*' | sed 's/:.*$//'))
    for tool in ${TOOLS_ARRAY[@]}
    do
        echo -e "\n### Installing ${tool} ###\n"
        if [ ! "$(yq -r ".${tool}.pre-install" templates/${file})" = 'null' ] ; then
            echo -e "\n# Pre-install #\n"
            yq -r ".${tool}.pre-install" templates/${file} | while read x ; do eval $x ; done
        fi
        VERSION=$(yq -r ".${tool}.version" templates/${file})
        if [ $VERSION == null ]; then
            VERSION=$(yq -r ".version.\"${DIST_VER}\".${tool}.default" dist/${DIST_ID}.yaml)
        fi
        echo -e "\n# Install #\n"
        yq -r ".version.\"${DIST_VER}\".${tool}.\"${VERSION}\".install" dist/${DIST_ID}.yaml | while read x ; do eval $x ; done
        
        if [ ! "$(yq -r ".${tool}.post-install" templates/${file})" = 'null' ] ; then
            echo -e "\n# Post Install #\n"
            yq -r ".${tool}.post-install" templates/${file} | while read x ; do eval $x ; done
        fi
    done
done

for file in ${USER_FILES[@]}
do
    echo -e "### installing user defined toolset for: ${file} ###"
    TOOLS_ARRAY=($(yq -r user/${file} | grep -v '^ .*' | sed 's/:.*$//'))
    for tool in ${TOOLS_ARRAY[@]}
    do
        echo -e "\n### Installing ${tool} ###\n"
        if [ ! "$(yq -r ".${tool}.pre-install" user/${file})" = 'null' ] ; then
            echo -e "\n# Pre-install #\n"
            yq -r ".${tool}.pre-install" user/${file} | while read x ; do eval $x ; done
        fi
        VERSION=$(yq -r ".${tool}.version" user/${file})
        if [ $VERSION == null ]; then
            VERSION=$(yq -r ".version.\"${DIST_VER}\".${tool}.default" dist/${DIST_ID}.yaml)
        fi
        echo -e "\n# Install #\n"
        yq -r ".version.\"${DIST_VER}\".${tool}.\"${VERSION}\".install" dist/${DIST_ID}.yaml | while read x ; do eval $x ; done
        
        if [ ! "$(yq -r ".${tool}.post-install" user/${file})" = 'null' ] ; then
            echo -e "\n# Post Install #\n"
            yq -r ".${tool}.post-install" user/${file} | while read x ; do eval $x ; done
        fi
    done
done
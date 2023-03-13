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
        *)
            echo "ERROR: Invalid option $1 provided." >&2
            show_help
            ;;
    esac
done

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
#!  /bin/bash

PROGDIR=$(dirname "$0")
PROGRAM=$(basename "$0")
usage() {
    cat <<EOT
    Usage: $PROGRAM OPTIONS [MARKDOWN FILE]...
        The following options are allowed:
        -h|--html           Make HTML
        -p|--pdf            Make PDF
        -q|--quick-html     Don't make self-contained HTML
        -o|--output         Specify output file's basename - an extension will be added
        -h|--help           Display this message
EOT
    exit 1
}

OPTIONS=$(getopt -n "$0" -o hpqo:h --long html,pdf,quick-html,output:,help -- "$@")
# shellcheck disable=SC2181
[[ $? -ne 0 ]] && usage

eval set -- "$OPTIONS"
DO_ALL=1
OUTPUT=
while true; do
    case $1 in
        -h | --html)
            DO_HTML=YES
            DO_ALL=
            ;;
        -q | --quick-html)
            DO_QUICK_HTML=YES
            ;;
        -p | --pdf)
            DO_PDF=YES
            DO_ALL=
            ;;
        -o | --output)
            OUTPUT=$2
            shift
            ;;
        --help)
            usage
            ;;
        --)
            shift
            break
            ;;
        "")
            break
            ;;
        *)
            usage
            ;;
    esac
    shift
done
[ $# -eq 0 ] && { printf "%s: No Markdown document supplied\n" "$0"; usage; exit 1; }
[ -n "$OUTPUT" ] && [ $# -gt 1 ] && { printf -- "%s: --output can only be used when 1 Markdown file is supplied\n" "$0"; usage; exit 1; }
[ -n "$DO_ALL" ] && { DO_HTML=YES; DO_PDF=YES; }
# shellcheck disable=SC2015
[ -n "$DO_QUICK_HTML" ] && { DO_HTML=YES; } || { SELF_CONTAINED=--self-contained; }

for file in "$@"; do
    THIS_OUTPUT=${OUTPUT:-${file%%.*}}
    [ -n "$DO_PDF" ] && env "PLANTUML=${PROGDIR}/filters/plantuml.jar" "TEXINPUTS=.:${PROGDIR}//:" pandoc "${file}" "--data-dir=${PROGDIR}" --defaults md2pdf -o "${THIS_OUTPUT}.pdf"
    [ -n "$DO_HTML" ] && env "PLANTUML=${PROGDIR}/filters/plantuml.jar" pandoc "${file}" "--data-dir=${PROGDIR}" --defaults md2html ${SELF_CONTAINED} -o "${THIS_OUTPUT}.html"
done
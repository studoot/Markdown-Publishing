#!  /bin/bash

PROGDIR=$(realpath -e "$(dirname "$0")")
PROGRAM=$(basename "$0")
PANDOC=${PANDOC:-$(command -v pandoc)}
usage() {
    cat <<EOT
    Usage: $PROGRAM OPTIONS [MARKDOWN FILE]...
        The following options are allowed:
        -h|--html           Make HTML
        -p|--pdf            Make PDF
        -t|--tex            Make TeX source code
        -o|--output         Specify output file's basename - an extension will be added
        -v|--verbose        Show conversion logs
        --help              Display this message

    By default, HTML and PDF output is produced. Selecting any of the output
    options (--html, --pdf or --tex) disables this default. 
EOT
    exit 1
}

OPTIONS=$(getopt -n "$0" -o hpto:v --long html,pdf,tex,output,verbose:,help -- "$@")
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
        -p | --pdf)
            DO_PDF=YES
            DO_ALL=
            ;;
        -t | --tex)
            DO_TEX=YES
            DO_ALL=
            ;;
        -o | --output)
            OUTPUT=$2
            shift
            ;;
        -v | --verbose)
            DO_VERBOSE=YES
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
[ $# -eq 0 ] && { printf "%s: No Markdown file(s) supplied\n" "$0"; usage; exit 1; }
[ -n "$OUTPUT" ] && [ $# -gt 1 ] && { printf "%s: --output can only be used when 1 Markdown file is supplied\n" "$0"; usage; exit 1; }
[ -n "$DO_ALL" ] && { DO_HTML=YES; DO_PDF=YES; }
# shellcheck disable=SC2015

for file in "$@"; do
    [ -f "$file" ] || { printf "%s: Argument %s is not a valid file path\n" "$0" "$file"; continue; }
    docname=$(basename "$file")
    docdir=$(dirname "$file")
    EXTRA_OPTIONS=()
	STATUS=$(git -C "$docdir" status --porcelain -- "$docname" 2>/dev/null)
	DATE=$(git -C "$docdir" log -n 1 --pretty=%cd --date=short -- "$docname" 2>/dev/null)
	if [ -z "$DATE" ] || [ -n "$STATUS" ]; then DATE=$(date -r "$(realpath -e "$file")" --iso-8601); fi
	COMMIT=$(git -C "$docdir" log -n 1 --pretty=%h --date=short -- "$docname" 2>/dev/null)
	if [ -n "$STATUS" ] && [ -n "$STATUS" ]; then COMMIT="${COMMIT} + modifications"; fi
    if [ -n "$COMMIT" ]; then EXTRA_OPTIONS+=("--variable=commit:${COMMIT}"); fi

    [ -n "$DO_VERBOSE" ] && EXTRA_OPTIONS+=("--verbose")
    EXTRA_DEFAULTS_FILE=${file%.*}-defaults.yaml
    [ -f "$EXTRA_DEFAULTS_FILE" ] && EXTRA_OPTIONS+=("--defaults=$EXTRA_DEFAULTS_FILE")
    THIS_OUTPUT=$(realpath -m "${OUTPUT:-${file%.*}}")
    [ -n "$DO_PDF" ] && env "TEXINPUTS=.:${PROGDIR}//:" "${PANDOC}" "${file}" "--data-dir=${PROGDIR}" --defaults md2pdf  -o "${THIS_OUTPUT}.pdf" "--metadata=plantuml_path:${PROGDIR}/filters/plantuml.jar" "--variable=date:${DATE}" "${EXTRA_OPTIONS[@]}" "--wrap=none"
    [ -n "$DO_TEX" ] && env "TEXINPUTS=.:${PROGDIR}//:" "${PANDOC}" "${file}" "--data-dir=${PROGDIR}" --defaults md2pdf  -o "${THIS_OUTPUT}.tex" "--metadata=plantuml_path:${PROGDIR}/filters/plantuml.jar" "--variable=date:${DATE}" "${EXTRA_OPTIONS[@]}" "--wrap=none"
    [ -n "$DO_HTML" ] && (
        cd "$docdir" || exit
        EXTRACT_DIR=$(mktemp --directory --tmpdir=.)
        "${PANDOC}" --fail-if-warnings "${docname}" "--data-dir=${PROGDIR}" --standalone --self-contained --defaults md2html --extract-media "$EXTRACT_DIR" -o "${THIS_OUTPUT}.html" "--metadata=plantuml_path:${PROGDIR}/filters/plantuml.jar" "--variable=date:${DATE}" "${EXTRA_OPTIONS[@]}";
    )
done
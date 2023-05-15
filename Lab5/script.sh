FAILED_OUT="\033[0;31m"
PASSED_OUT="\033[0;32m"
NONE_OUT="\033[0m"

pretty-printer-box() {
:<<DOC
    Provides pretty-printer check box
DOC
    echo "Start ${1} analysis ..."
}

remove-pycache() {
:<<DOC
    Removes python cache directories
DOC
    ( find . -depth -name __pycache__ | xargs rm -r )
}

check-flake() {
:<<DOC
    Runs "flake8" code analysers
DOC
    pretty-printer-box "flake" && ( flake8 ./ )
}

is-passed() {
:<<DOC
    Checks if code assessment is passed
DOC
    if [[ $? -ne 0 ]]; then
      echo -e "${FAILED_OUT}Code assessment is failed, please fix errors!${NONE_OUT}"
      exit 100
    else
      echo -e "${PASSED_OUT}Congratulations, code assessment is passed!${NONE_OUT}"
    fi
}

main() {
:<<DOC
    Runs "main" code analyser
DOC
    (
	  remove-pycache
      check-flake && \ 
	  is-passed
    )
}

main
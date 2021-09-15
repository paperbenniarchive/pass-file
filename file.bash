#!/bin/bash

VERSION="0.0.0"

addfile() {
    if [ -z "$2" ]; then
        echo "Usage: $PROGRAM file insert file-name filepath"
        return 1
    fi

    local path="$1"
    local targetfile="$(realpath "$2")"

    if ! [ -e "$targetfile" ]; then
        echo "target $targetfile does not exist"
    fi

    local passfile="$PREFIX/$path.file.gpg"

    check_sneaky_paths "$path"

    if [ -e "$passfile" ]; then
        yesno "file $path already exists, overwrite?"
    fi
    # TODO: check for large file size

    mkdir -p -v "$PREFIX/$(dirname "$path")"
    set_gpg_recipients "$(dirname "$path")"
    set_git "$passfile"

    $GPG -o "$passfile" --encrypt "${GPG_RECIPIENT_ARGS[@]}" "${GPG_OPTS[@]}" "$targetfile"

    git_add_file "$passfile" "added encrypted file $path"

}

exportfile() {
    local path="$1"
    local target="$2"
    local passfile="$PREFIX/$path.file.gpg"
    if [ -z "$2" ]; then
        echo "Usage: $PROGRAM file export file-name path"
        return 1
    fi
    [ -e "$passfile" ] || {
        echo "file $path does not exist"
        return 1
    }
    $GPG -o "$target" --decrypt "${GPG_OPTS[@]}" "$passfile"

}

echohelp() {
    cat <<EOF
Usage:
	$PROGRAM file insert file-name filepath
	    add an encrypted binary file to the password store
	$PROGRAM file export file-name [target-path]
	    export a entry from the password store
	    to disk as an unencrypted file
EOF

}

case "$1" in
insert)
    shift 1
    addfile "$1" "$2"
    ;;
export)
    shift 1
    exportfile "$1" "$2"
    ;;
*)
    echohelp
    ;;
esac

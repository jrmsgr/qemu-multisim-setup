# Utils file meant to be sourced

REPO_ROOT=$(git rev-parse --show-toplevel)

error() {
    echo "ERROR: $1" >&2
    exit 1
}

banner() {
    echo "##########################################"
    echo "$1"
    echo "##########################################"
}

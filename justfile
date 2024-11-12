# display this help menu
list:
    @just --list

# build static site
build:
    mdbook build

# run code linters to check formatting
lint:
    markdownlint --config .markdownlint.yaml '**/*.md'

# run dev env with livereload, for local editing
dev:
    mdbook serve -n 127.0.0.1

# run dev env via firebase, for a more prod-like local editing experience
firebase-dev:
    @just build
    firebase emulators:start

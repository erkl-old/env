# Set environment variables specific to go.
export GOPATH="$HOME/.go"
export GOROOT="/usr/local/go"

# Add installed go binaries to PATH.
export PATH="$PATH:$GOPATH/bin:$GOROOT/bin"

# Convenient cd shortcuts.
export CDPATH=".:$GOPATH/src/code.google.com/p:$GOPATH/src/github.com"

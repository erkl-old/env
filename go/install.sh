#!/usr/bin/env sh
set -ex

# Pull down the prefered version if it's not already installed.
VERSION="go1.3.3"

if [[ ! -e "/usr/local/go/VERSION" || $(cat "/usr/local/go/VERSION") != "$VERSION" ]]; then
	rm -rf /usr/local/go
	wget -qO - "https://storage.googleapis.com/golang/$VERSION.linux-amd64.tar.gz" | tar -C /usr/local -xzf

	# Make sure the $GOPATH directory exists.
	mkdir "$HOME/.go"
fi

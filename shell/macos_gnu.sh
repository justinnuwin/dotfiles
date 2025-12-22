#!/bin/bash
if [[ -d /usr/local/opt/coreutils ]]; then

  # brew install coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep

  PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
  PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
  PATH="/usr/local/opt/gnu-indent/libexec/gnubin:$PATH"
  PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
  PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
  export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"

  export CPPFLAGS="-I/usr/local/opt/readline/include"
  export LDFLAGS="-L/usr/local/opt/readline/lib"

  export PATH="/usr/local/opt/gettext/bin:$PATH"
  export CPPFLAGS="-I/usr/local/opt/gettext/include"
  export LDFLAGS="-L/usr/local/opt/gettext/lib"

  export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
  export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
  export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"

  export LDFLAGS="-L/usr/local/opt/libffi/lib"

fi

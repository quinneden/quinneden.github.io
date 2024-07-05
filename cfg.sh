#!/usr/bin/env bash

main() {
  if [[ -n $1 ]] && [[ $1 == */* ]]; then
    FWF=$(find $dotdir -type f -iwholename "*$1*")
    if [[ ! -f $FWF || $FWF == .* ]]; then
      echo "File not found."
    else
      micro "$FWF"
    fi
  elif [[ -n $1 ]] && [[ $1 != */* ]]; then
    FF=$(find $dotdir -type f -iname "*$1*")
    if [[ ! -f $FF || $FF == */.* ]]; then
      echo "File not found."
    else
      micro "$FF"
    fi
  else
    micro $dotdir/flake.nix
  fi
}

main $@ && exit 0

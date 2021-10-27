#!/usr/bin/env bash

export PYTORCH_LATEST="1.10.0"

pytorch_required_cuda() {
  case $1 in
    "1.10.0")
      echo "11.3" "10.2"
      ;;
    "1.9.1" | "1.9.0" | "1.8.0")
      echo "11.1" "10.2"
      ;;
    "1.7.1")
      echo "11.0" "10.2" "10.1" "9.2"
      ;;
    "1.7.0" | "1.6.0" | "1.5.1" | "1.5.0")
      echo "10.2" "10.1" "9.2"
      ;;
    *)
      echo "PyTorch $PYTORCH is not supported"
      exit 0
      ;;
  esac
}

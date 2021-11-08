#!/usr/bin/env bash

export TENSORFLOW_LATEST="2.7.0"

tensorflow_required_cuda() {
  case $1 in
    "2.7.0")
      echo "11.2"
      ;;
    "2.6.1" | "2.6.0")
      echo "11.2"
      ;;
    "2.5.2" | "2.5.1" | "2.5.0")
      echo "11.2"
      ;;
    "2.4.4" | "2.4.3" | "2.4.2" | "2.4.1" | "2.4.0")
      echo "11.0"
      ;;
    "2.3.4" | "2.3.3" | "2.3.2" | "2.3.1" | "2.3.0")
      echo "10.1"
      ;;
    "2.2.3" | "2.2.2" | "2.2.1" | "2.2.0")
      echo "10.1"
      ;;
    "2.1.4" | "2.1.3" | "2.1.2" | "2.1.1" | "2.1.0")
      echo "10.1"
      ;;
    "2.0.4" | "2.0.3" | "2.0.2" | "2.0.1" | "2.0.0")
      echo "10.0"
      ;;
    "1.15.5" | "1.15.4" | "1.15.3" | "1.15.2" | "1.15.1" | "1.15.0")
      echo "10.0"
      ;;
    *)
      echo "TensorFlow $1 is not supported"
      exit 0
      ;;
  esac
}

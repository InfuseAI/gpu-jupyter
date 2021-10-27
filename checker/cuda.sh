#!/usr/bin/env bash

export CUDA_LATEST="11.3"

cuda_root_container() {
  case $1 in
    "11.3")
      export HEAD_COMMIT=$UBUNTU_20_04_HEAD_COMMIT
      echo "nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04"
      ;;
    "11.2")
      export HEAD_COMMIT=$UBUNTU_20_04_HEAD_COMMIT
      echo "nvidia/cuda:11.2.2-cudnn8-runtime-ubuntu20.04"
      ;;
    "11.1")
      export HEAD_COMMIT=$UBUNTU_20_04_HEAD_COMMIT
      echo "nvidia/cuda:11.1.1-cudnn8-runtime-ubuntu20.04"
      ;;
    "11.0")
      export HEAD_COMMIT=$UBUNTU_20_04_HEAD_COMMIT
      echo "nvidia/cuda:11.0.3-cudnn8-runtime-ubuntu20.04"
      ;;
    "10.2")
      export HEAD_COMMIT=$UBUNTU_18_04_HEAD_COMMIT
      echo "nvidia/cuda:10.2-cudnn7-runtime-ubuntu18.04"
      ;;
    "10.1")
      export HEAD_COMMIT=$UBUNTU_18_04_HEAD_COMMIT
      echo "nvidia/cuda:10.1-cudnn7-runtime-ubuntu18.04"
      ;;
    "10.0")
      export HEAD_COMMIT=$UBUNTU_18_04_HEAD_COMMIT
      echo "nvidia/cuda:10.0-cudnn7-runtime-ubuntu18.04"
      ;;
    "9.2")
      export HEAD_COMMIT=$UBUNTU_18_04_HEAD_COMMIT
      echo "nvidia/cuda:9.2-cudnn7-runtime-ubuntu18.04"
      ;;
    *)
      echo "CUDA $CUDA is not supported"
      exit 0
      ;;
  esac
}

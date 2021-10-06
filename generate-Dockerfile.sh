#!/usr/bin/env bash
cd $(cd -P -- "$(dirname -- "$0")" && pwd -P)

# Import checkers
source checker/*.sh

# Set the path of the generated Dockerfile
export DOCKERFILE=".build/Dockerfile"
export STACKS_DIR=".build/docker-stacks"
# please test the build of the commit in https://github.com/jupyter/docker-stacks/commits/master in advance
export HEAD_COMMIT="310edebfdcff1ed58444b88fc0f7c513751e30bd"

while [[ $# -gt 0 ]]; do
  case $1 in
    -p | --pw | --password)
      PASSWORD="$2" && USE_PASSWORD=1
      shift
      ;;
    -c | --commit)
      HEAD_COMMIT="$2"
      shift
      ;;
    --cuda)
      CUDA="$2"
      shift
      ;;
    --tensorflow)
      TENSORFLOW="$2"
      shift
      ;;
    --pytorch)
      PYTORCH="$2"
      shift
      ;;
    --generate-tag) generate_tag=1 ;;
    --base-notebook) base_notebook=1 ;;
    --tensorflow-notebook) tensorflow_notebook=1 ;;
    --pytorch-notebook) pytorch_notebook=1 ;;
    --gpu) GPU=1 ;;
    --zhfonts) zhfonts=1 ;;
    --no-opencv) no_opencv=1 ;;
    --tensorboard) tensorboard=1 ;;
    -h | --help) HELP=1 ;;
    *) echo "Unknown parameter passed: $1" && HELP=1 ;;
  esac
  shift
done

if [[ $HELP == 1 ]]; then
  echo "Help for ./generate-Dockerfile.sh:"
  echo "Usage: $0 [parameters]"
  echo "    -h|--help: Show this help."
  echo "    -p|--pw|--password: Set the password (and update in src/jupyter_notebook_config.json)"
  echo "    -c|--commit: Set the head commit of the jupyter/docker-stacks submodule (https://github.com/jupyter/docker-stacks/commits/master). default: $HEAD_COMMIT."
  echo "    --no-datascience-notebook|--python-only: Use not the datascience-notebook from jupyter/docker-stacks, don't install Julia and R."
  echo "    --no-useful-packages: Don't install the useful packages, specified in src/Dockerfile.usefulpackages"
  echo "    --slim: no useful packages and no datascience notebook."
  exit 21
fi

UBUNTU_20_04_HEAD_COMMIT="310edebfdcff1ed58444b88fc0f7c513751e30bd"
UBUNTU_18_04_HEAD_COMMIT="3fe198a1fd4625d833654b1112cb15fade47c2c1"

if [[ ! $TENSORFLOW ]] && [[ $tensorflow_notebook ]]; then
  TENSORFLOW=$TENSORFLOW_LATEST
fi

if [[ ! $PYTORCH ]] && [[ $pytorch_notebook ]]; then
  PYTORCH=$PYTORCH_LATEST
fi

ROOT_CONTAINER="ubuntu:focal"
export HEAD_COMMIT=$UBUNTU_20_04_HEAD_COMMIT
if [[ $GPU == 1 ]] || [[ $CUDA ]]; then
  GPU=1

  if [[ $TENSORFLOW ]]; then
    REQUIRED_CUDA=$(tensorflow_required_cuda $TENSORFLOW)
  fi

  if [[ $PYTORCH ]]; then
    REQUIRED_CUDA=$(pytorch_required_cuda $PYTORCH)
  fi

  # turn into array
  REQUIRED_CUDA=($REQUIRED_CUDA)

  if [[ $REQUIRED_CUDA ]]; then
    if [[ $CUDA ]]; then
      if [[ ! " ${REQUIRED_CUDA[*]} " =~ " ${CUDA} " ]]; then
        echo "CUDA version unmatched!"
        exit 0
      fi
    else
      CUDA=$REQUIRED_CUDA
    fi
  else
    CUDA=$CUDA_LATEST
  fi

  ROOT_CONTAINER=$(cuda_root_container $CUDA)
fi

if [[ $generate_tag ]]; then
  if [[ $base_notebook ]]; then
    TAG="base"
  fi

  if [[ $tensorflow_notebook ]]; then
    TAG=tensorflow-v${TENSORFLOW//\./-}
  fi

  if [[ $pytorch_notebook ]]; then
    TAG=pytorch-v${PYTORCH//\./-}
  fi

  if [[ $CUDA ]]; then
    TAG=${TAG}-gpu-cuda-${CUDA//\./-}
  fi

  echo $TAG
  exit 0
fi

# Clone if docker-stacks doesn't exist, and set to the given commit or the default commit
ls $STACKS_DIR/README.md >/dev/null 2>&1 || (echo "Docker-stacks was not found, cloning repository" \
  && git clone https://github.com/jupyter/docker-stacks.git $STACKS_DIR)
echo "Set docker-stacks to commit '$HEAD_COMMIT'."
if [[ $HEAD_COMMIT == "latest" ]]; then
  echo "WARNING, the latest commit of docker-stacks is used. This may result in version conflicts"
  cd $STACKS_DIR && git pull && cd -
else
  export GOT_HEAD="false"
  cd $STACKS_DIR && git pull && git reset --hard "$HEAD_COMMIT" >/dev/null 2>&1 && cd - && export GOT_HEAD="true"
  echo "$HEAD"
  if [[ $GOT_HEAD == "false" ]]; then
    echo "Error: The given sha-commit is invalid."
    echo "Usage: $0 -c [sha-commit] # set the head commit of the docker-stacks submodule (https://github.com/jupyter/docker-stacks/commits/master)."
    echo "Exiting"
    exit 2
  else
    echo "Set head to given commit."
  fi
fi

# Write the contents into the DOCKERFILE and start with the header
echo "# This Dockerfile is generated by 'generate-Dockerfile.sh' from elements within 'src/'

# **Please do not change this file directly!**
# To adapt this Dockerfile, adapt 'generate-Dockerfile.sh' or 'src/Dockerfile.usefulpackages'.
# More information can be found in the README under configuration.

" >$DOCKERFILE
# cat src/Dockerfile.header >>$DOCKERFILE
echo "FROM ${ROOT_CONTAINER}" >>$DOCKERFILE

echo "
############################################################################
#################### Dependency: jupyter/base-image ########################
############################################################################
" >>$DOCKERFILE
cat $STACKS_DIR/base-notebook/Dockerfile | grep -v 'ROOT_CONTAINER\|BASE_CONTAINER' >>$DOCKERFILE

# copy files that are used during the build:
cp $STACKS_DIR/base-notebook/jupyter_notebook_config.py .build/
cp $STACKS_DIR/base-notebook/fix-permissions .build/
cp $STACKS_DIR/base-notebook/start.sh .build/
cp $STACKS_DIR/base-notebook/start-notebook.sh .build/
cp $STACKS_DIR/base-notebook/start-singleuser.sh .build/
chmod 755 .build/*

echo "
############################################################################
######################### Dependency: primehub #############################
############################################################################
" >>$DOCKERFILE
cat src/Dockerfile.primehub >>$DOCKERFILE

if [[ $zhfonts ]]; then
  echo "
############################################################################
######################### Dependency: zh fonts #############################
############################################################################
" >>$DOCKERFILE
  cat src/Dockerfile.zhfonts >>$DOCKERFILE
fi

if [[ ! $no_opencv ]]; then
  echo "
############################################################################
########################## Dependency: opencv ##############################
############################################################################
" >>$DOCKERFILE
  cat src/Dockerfile.opencv >>$DOCKERFILE
fi

if [[ ! $base_notebook ]]; then
  echo "
############################################################################
################# Dependency: jupyter/minimal-notebook #####################
############################################################################
" >>$DOCKERFILE
  cat $STACKS_DIR/minimal-notebook/Dockerfile | grep -v BASE_CONTAINER >>$DOCKERFILE

  echo "
############################################################################
################# Dependency: jupyter/scipy-notebook #######################
############################################################################
" >>$DOCKERFILE
  cat $STACKS_DIR/scipy-notebook/Dockerfile | grep -v BASE_CONTAINER >>$DOCKERFILE

  if [[ $TENSORFLOW ]]; then
    echo "ARG TENSORFLOW_VERSION=${TENSORFLOW}" >>$DOCKERFILE
    if [[ $CUDA ]]; then
      echo "ARG TENSORFLOW_PREFIX=-gpu" >>$DOCKERFILE
      echo "ENV TF_FORCE_GPU_ALLOW_GROWTH=true" >>$DOCKERFILE
    fi
    cat src/Dockerfile.tensorflow >>$DOCKERFILE
    tensorboard=1
  fi

  if [[ $PYTORCH ]]; then
    echo "ARG PYTORCH_VERSION=${PYTORCH}" >>$DOCKERFILE
    echo "ARG CUDA=${CUDA}" >>$DOCKERFILE
    cat src/Dockerfile.pytorch >>$DOCKERFILE
  fi

  if [[ $tensorboard ]]; then
    cat src/Dockerfile.tensorboard >>$DOCKERFILE
  fi
fi

# Copy the demo notebooks and change permissions
cp -r extra/Getting_Started data
chmod -R 755 data/

# set password
if [[ $USE_PASSWORD == 1 ]]; then
  echo "Set password to given input"
  SALT="3b4b6378355"
  HASHED=$(echo -n ${PASSWORD}${SALT} | sha1sum | awk '{print $1}')
  unset PASSWORD # delete variable PASSWORD
  # build jupyter_notebook_config.json
  echo "{
  \"NotebookApp\": {
    \"password\": \"sha1:$SALT:$HASHED\"
  }
}" >src/jupyter_notebook_config.json
fi

cp src/jupyter_notebook_config.json .build/
echo >>$DOCKERFILE
echo "# Copy jupyter_notebook_config.json" >>$DOCKERFILE
echo "COPY jupyter_notebook_config.json /etc/jupyter/" >>$DOCKERFILE

# Set environment variables
export JUPYTER_UID=$(id -u)
export JUPYTER_GID=$(id -g)

#cp $(find $(dirname $DOCKERFILE) -type f | grep -v $STACKS_DIR | grep -v .gitkeep) .
echo
echo "The GPU Dockerfile was generated successfully in file ${DOCKERFILE}."
echo "To start the GPU-based Juyterlab instance, run:"
echo "  docker build -t gpu-jupyter .build/  # will take a while"
echo "  docker run --gpus all -d -it -p 8848:8888 -v $(pwd)/data:/home/jovyan/work -e GRANT_SUDO=yes -e JUPYTER_ENABLE_LAB=yes -e NB_UID=$(id -u) -e NB_GID=$(id -g) --user root --restart always --name gpu-jupyter_1 gpu-jupyter"

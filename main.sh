
__getIndexInCurrentWords() {
  WORD=$1

  for i in "${!WORD_ITEMS[@]}"; do
     if [[ "${WORD_ITEMS[$i]}" == "${WORD}" ]]; then
         echo ${i}
         return 0
     fi
  done

  echo "not found"
  return 0
}

__getYMLFiles() {
  echo $(find * -type f -name "*.yml" 2> /dev/null)
  return 0
}

__getArchiveFiles() {
  echo $(find * -type f -name "*.tgz" -o -name "*.gz" -o -name "*.tar" -o -name "*.gzip" -o -name "*.zip" 2> /dev/null)
  return 0
}

__getValueSetInKeyVal() {
  WORD=$1
  for i in "${!WORD_ITEMS[@]}"; do
     if [[ "${WORD_ITEMS[$i]}" == *"${WORD}"* ]]; then
        IFS='=' read -ra KEYVALUE <<< "${WORD_ITEMS[$i]}"

        if [[ "${#KEYVALUE[@]}" == 2 ]]; then
          echo "${KEYVALUE[1]}"
          return 0
        else
          echo "value not set"
          return 1
        fi
     fi
  done

  echo "not found"
  return 1
}

__getEnvs() {
  # results=`eval "bosh envs --json | jq -r '.Tables[0].Rows[][1]' | tr '\n' ' '"`
  results=`eval "cat blah | jq -r '.Tables[0].Rows[][1]' | tr '\n' ' '"`

  echo ${results}
  return 0
}

__getColumnValues() {
  json=$1
  colname=$2
  results=$(echo ${json} | jq -r .Tables[0].Rows[].${colname} 2> /dev/null)
  echo ${results}
  return 0
}

__getDeployments() {
  json=$(bosh -e ${ENVIRONMENT} deployments --json 2> /dev/null)
  results=$(__getColumnValues "${json}" name 2> /dev/null)
  echo ${results}
  return 0
}

__getErrands() {
  json=$(bosh -e ${ENVIRONMENT} -d ${DEPLOYMENT} errands --json 2> /dev/null)
  results=$(__getColumnValues "${json}" name 2> /dev/null)
  echo ${results}
  return 0
}
__getReleases() {
  results=$(bosh -e ${ENVIRONMENT} releases --column=name --column==version --json | jq -r '.Tables[0].Rows[] | .name+"/"+.version' 2> /dev/null)
  echo ${results}
  return 0
}

__getStemcells() {
  results=$(bosh -e ${ENVIRONMENT} stemcells --column=name --column==version --json | jq -r '.Tables[0].Rows[] | .name+"/"+.version' 2> /dev/null)
  echo ${results}
  return 0
}

__getDeployment() {
  depFlagIndex=$(__getIndexInCurrentWords "-d")
  deploymentFlag=$(__getValueSetInKeyVal "--deployment=")

  if [[ ("${depFlagIndex}" == "not found") && ("${deploymentFlag}" == "not found") ]]; then
    if [ "${BOSH_DEPLOYMENT}" == "" ]; then
      echo "error not set"
      return 1;
    else 
      echo "${BOSH_DEPLOYMENT}"
      return 0;
    fi
  elif [[ ("${depFlagIndex}" == "not found") ]]; then
    echo "${deploymentFlag}"
    return 0
  else
    echo "${COMP_WORDS[depFlagIndex + 1]}"
    return 0
  fi
}

__getEnvironment() {
  envFlagIndex=$(__getIndexInCurrentWords "-e")
  environmentFlag=$(__getValueSetInKeyVal "--environment=")

  if [[ ("${envFlagIndex}" == "not found") && ("${environmentFlag}" == "not found") ]]; then
    if [ "${BOSH_ENVIRONMENT}" == "" ]; then
      echo "error not set"
      return 1;
    else 
      echo "${BOSH_ENVIRONMENT}"
      return 0;
    fi
  elif [[ ("${envFlagIndex}" == "not found") ]]; then
    echo "${environmentFlag}"
    return 0
  else
    echo "${COMP_WORDS[envFlagIndex + 1]}"
    return 0
  fi
}

__allFiles() {
  results=`eval "ls -A"`
  echo "${results}"
}

__allDirs() {
  results=`eval "ls -d -- */"`
  echo ${results}
  return 0
}

__getVMs() {
  json=$(bosh vms -e ${ENVIRONMENT} -d ${DEPLOYMENT} --column=instance --json 2> /dev/null)
  results=$(__getColumnValues "${json}" instance 2> /dev/null)
  echo ${results}
  return 0
}

__removeEnvironmentFromCommands() {
  ENV_INDEX=$(__getIndexInCurrentWords "${ENVIRONMENT}")

  if [[ "${ENVIRONMENT}" == *"--environment"* ]]; then
    WORD_ITEMS=(${WORD_ITEMS[@]:0:$ENV_INDEX} ${WORD_ITEMS[@]:$(($ENV_INDEX + 1))})
    COMP_CWORD=${COMP_CWORD}-1

    echo "${WORD_ITEMS[@]}"
    return 0
  else 
    WORD_ITEMS=(${WORD_ITEMS[@]:0:$ENV_INDEX} ${WORD_ITEMS[@]:$(($ENV_INDEX + 1))})
    WORD_ITEMS=(${WORD_ITEMS[@]:0:$ENV_INDEX - 1} ${WORD_ITEMS[@]:$(($ENV_INDEX))})
    COMP_CWORD=${COMP_CWORD}-2

    echo "${WORD_ITEMS[@]}"
    return 0
  fi
}

__removeDeploymentFromCommands() {
  DEP_INDEX=$(__getIndexInCurrentWords "${DEPLOYMENT}")

  if [[ "${DEPLOYMENT}" == *"--deployment"* ]]; then
    WORD_ITEMS=(${WORD_ITEMS[@]:0:$ENV_INDEX} ${WORD_ITEMS[@]:$(($ENV_INDEX + 1))})
    COMP_CWORD=${COMP_CWORD}-1

    echo "${WORD_ITEMS[@]}"
    return 0
  else 
    WORD_ITEMS=(${WORD_ITEMS[@]:0:$ENV_INDEX} ${WORD_ITEMS[@]:$(($ENV_INDEX + 1))})
    WORD_ITEMS=(${WORD_ITEMS[@]:0:$ENV_INDEX - 1} ${WORD_ITEMS[@]:$(($ENV_INDEX))})
    COMP_CWORD=${COMP_CWORD}-2

    echo "${WORD_ITEMS[@]}"
    return 0
  fi
}

function _boshness() {
  local main_options="-e add-blob alias-env attach-disk back-up blobs cancel-task clean-up cloud-check 
  cloud-config cpi-config create-env create-release delete-deployment delete-disk delete-env delete-release 
  delete-snapshot delete-snapshots delete-stemcell delete-vm deploy deployment deployments disks environment 
  environments envs errands events export-release finalize-release generate-job generate-package help ignore
  init-release inspect-release instances interpolate locks log-in log-out logs manifest recreate releases remove-blob
  reset-release restart run-errand runtime-config scp snapshots ssh start stemcells stop sync-blobs take-snapshot task
  tasks unignore update-cloud-config update-cpi-config update-resurrection update-runtime-config upload-blobs upload-release
  upload-stemcell variables vms"
  local no_options=""
  local back_up_options="--force"
  local just_dir_options="--dir"
  local all_options="-v --version --sha2 --json --tty --no-color -h --help"

  local cur prev opts

  COMPREPLY=()

  WORD_ITEMS=( "${COMP_WORDS[@]}" )

  ENVIRONMENT=$(__getEnvironment)
  if [[ ${ENVIRONMENT} != "error not set" ]]; then
    __removeEnvironmentFromCommands "${ENVIRONMENT}"
  fi

  DEPLOYMENT=$(__getDeployment)
  if [[ ${DEPLOYMENT} != "error not set" ]]; then
    __removeDeploymentFromCommands "${DEPLOYMENT}"
  fi

  cur="${WORD_ITEMS[COMP_CWORD]}"
  prev="${WORD_ITEMS[COMP_CWORD-1]}"


  if [[ ${prev} == bosh ]]; then
    if [[ ${cur} == * ]] ; then
      COMPREPLY=( $(compgen -W "${main_options[@]} ${all_options[@]}" -- ${cur}) )
      return 0
    fi
  elif [[ (${prev} == add-blob) || (${prev} == blobs) ]]; then
    COMPREPLY=( $(compgen -W "${just_dir_options}" -- ${cur}) )
    return 0
  elif [[ (${prev} == alias-env) || (${prev} == attach-disk) || (${prev} == cancel-task)]]; then
    COMPREPLY=( $(compgen -W "${no_options}" -- ${cur}) )
    return 0
  elif [[ ${prev} == back-up ]]; then
    COMPREPLY=( $(compgen -W "${back_up_options}" -- ${cur}) )
    return 0
  elif [[ (${prev} == -d) || \
	  (${prev} == --deployment) || \
	  (${prev} == delete-deployment)]]; then
    COMPREPLY=( $(compgen -W "`__getDeployments`" -- ${cur}) )
    return 0
  elif [[ ${prev} == -e ]]; then
    COMPREPLY=( $(compgen -W "`__getEnvs`" -- ${cur}) )
    return 0
  elif [[ ${prev} == -xx ]]; then
    COMPREPLY=( $(compgen -W "`__allDirs`" -- ${cur}) )
    return 0
  elif [[ ${prev} == upload-stemcell ]]; then
    COMPREPLY=( $(compgen -W "`__getArchiveFiles`" -- ${cur}) )
    return 0
  elif [[ (${prev} == update-cloud-config) || \
	  (${prev} == update-runtime-config) || \
	  (${prev} == update-cpi-config) || \
	  (${prev} == create-env) || \
	  (${prev} == delete-env) || \
	  (${prev} == interpolate) ]]; then
    COMPREPLY=( $(compgen -W "`__getYMLFiles`" -- ${cur}) )
    return 0
  elif [[ (${prev} == run-errand) ]]; then
    COMPREPLY=( $(compgen -W "`__getErrands`" -- ${cur}) )
    return 0
  elif [[ (${prev} == delete-release) ]]; then
    COMPREPLY=( $(compgen -W "`__getReleases`" -- ${cur}) )
    return 0
  elif [[ (${prev} == delete-stemcell) ]]; then
    COMPREPLY=( $(compgen -W "`__getStemcells`" -- ${cur}) )
    return 0
  elif [[ (${prev} == ssh) || \
	  (${prev} == start) || \
	  (${prev} == stop) || \
	  (${prev} == ignore) || \
	  (${prev} == unignore) ]]; then
    COMPREPLY=( $(compgen -W "`__getVMs`" -- ${cur}) )
    return 0
  fi
}

complete -F _boshness bosh

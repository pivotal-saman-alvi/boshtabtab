__getEnvs() {
  # results=`eval "bosh envs --json | jq -r '.Tables[0].Rows[][1]' | tr '\n' ' '"`
  results=`eval "cat blah | jq -r '.Tables[0].Rows[][1]' | tr '\n' ' '"`

  echo ${results}
  return 0
}

__getDeployments() {
  results=`eval "bosh deployments --json | jq .Tables[0].Rows | jq -r '.[] | select(.name) | .name'"`
  echo ${results}
  return 0
}

__getDeployment() {
  return $BOSH_DEPLOYMENT
}

__getEnvironment() {
  return $BOSH_ENVIRONMENT
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

# __getVMs() {
#   # TODO set this as output of getDeployment
#   bosh_deployment=$BOSH_DEPLOYMENT
#   results=`eval "bosh vms -d ${bosh_deployment}" 
# }

function _boshness() {
  local main_options="-xx -e add-blob alias-env attach-disk back-up blobs cancel-task clean-up cloud-check 
  cloud-config cpi-config create-env create-release delete-deployment delete-disk delete-env delete-release 
  delete-snapshot delete-snapshots delete-stemcell delete-vm deploy deployment deployments disks environment 
  environments envs errands events export-release finalize-release generate-job generate-package help ignore
  init-release inspect-release instances interpolate locks log-in log-out logs manifest recreate releases remove-blob
  reset-release restart run-errand runtime-config scp snapshots ssh start stemcells stop sync-blobs take-snapshot task
  tasks unignore update-cloud-config update-cpi-config update-resurrection update-runtime-config upload-blobs upload-release upload-stemcell variables vms"
  local no_options=""
  local back_up_options="--force"
  local just_dir_options="--dir"
  local all_options="-v --version --sha2 --json --tty --no-color -h --help"

  local cur prev opts

  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

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
  elif [[ (${prev} == -d) || (${prev} == --deployment) ]]; then
    COMPREPLY=( $(compgen -W "`__getDeployments`" -- ${cur}) )
    return 0
  elif [[ ${prev} == -e ]]; then
    COMPREPLY=( $(compgen -W "`__getEnvs`" -- ${cur}) )
    return 0
  elif [[ ${prev} == -xx ]]; then
    COMPREPLY=( $(compgen -W "`__allDirs`" -- ${cur}) )
    return 0
  elif [[ (${prev} == update-cloud-config) || \
	 				(${prev} == update-runtime-config) || \
	 				(${prev} == update-cpi-config) ]]; then
		COMPREPLY=( $(compgen -W "`__allFiles`" -- ${cur}) )
    return 0
  fi
}

complete -F _boshness bosh

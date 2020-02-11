#!/bin/bash

set -e
# i.e.
# PS /home/michal/workspace/onho.io> ./scripts/build.sh cid v0.1
usage(){
        cat <<EOF
        Usage: $(basename "$0") <COMMAND>  <TAG>
        Commands:
            ci                run build process with new version and properly tag
            cd                deploy app to container registry, redeploy k8s, install certificates
            cicd               ci+cd

        Command arguments:
            ci
                <TAG> required   docker tag, if empty than :latest is used

            cd
                <TAG> required   docker tag, if empty than :latest is used

            cicd
                <TAG> required   docker tag, if empty than :latest is used
EOF
}


panic() {
  (>&2 echo "$@")
  exit 1
}

check_kube_cli(){
	KUBECTL=`which kubectl`||true

	if [[ -z "${KUBECTL}" ]]; then
 		panic "Kubectl is not installed"
		exit 1
	fi
}


check_namespace_exists(){
  ns=$(kubectl get namespace lb-system -o=jsonpath='{.metadata.name}')
  if [ "$ns" != "lb-system" ]
then
   panic "missing namespace lb-system "
	 exit 1
fi

}

ci(){
cat <<EOF
***************************************************************
    building docker image
***************************************************************
EOF

    docker build . -t acronhosbx.azurecr.io/htp:"${tag}" --no-cache

    docker push acronhosbx.azurecr.io/htp:"${tag}"

    #remove dangling images https://www.projectatomic.io/blog/2015/07/what-are-docker-none-none-images/
    docker rmi $(docker images -f "dangling=true" -q) -f
}



cd(){
cat <<EOF
***************************************************************
    deploying lb
***************************************************************
EOF
    check_kube_cli
    check_namespace_exists

    yaml="$(cat ./deployment.yaml )"
    buildVersion="$tag"_$(date '+%y%m.%d.%H%M')
    bind="$(echo "$yaml" | sed -e "s|\${tag}|${tag}|g" | sed -e "s|\${buildVersion}|${buildVersion}|g")"

    # in order to download the newest docker from repo, forcing pod to restart and  do not take care if something is deployed or not
    #ensures that lb server will be redeployed by each cicd
    kubectl scale deployment httpsproxy -n proxy-system `` --replicas=0 2>/dev/null || true

cat <<EOF | kubectl apply -f -
`echo "$bind"`
EOF

}



if [[ "$#" -lt 2 ]]; then
  usage
  exit 1
fi
tag=${2}

case "$1" in
    "ci")
       ci
       exit 0
    ;;
    "cd")
      cd
      exit 0
    ;;
    "cicd")
        ci
        cd
    ;;
      *)
  usage
  exit 0
  ;;
esac






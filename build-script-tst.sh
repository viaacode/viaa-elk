#!/bin/bash

# Project name
PROJECT=viaa-elk

# User inputs
# Build or deploy
ACTION=$1
VERSION=$2 
ENVIRONMENT=$3
TAG=$(oc -n $PROJECT get is/${PROJECT} -o jsonpath={.status.tags[1].tag})

case $ACTION in
	build)
		# Verson number
		# Assume tags[0] is latest
		if [ -z "${VERSION}" ]; then
			echo Previous version is $TAG
			if [ -z "$TAG" ]; then 
				PREVERSION=v0.1
			else
				PREVERSION=$TAG
			fi
			MAJVERSION=$(echo $PREVERSION | cut -d'.' -f1)
			let MINVERSION=$(echo $PREVERSION | cut -d'.' -f2)+1
			VERSION=${MAJVERSION}.${MINVERSION}
		fi
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		echo "You are buliding version" $VERSION
#		sed -e "s/%buildversion%/${VERSION}/g" build-template.yaml > build.yaml
		if [[ $(oc -n $PROJECT get bc | grep -c ${PROJECT}) -gt 0 ]]; then
			#oc replace -n $PROJECT -f build.yaml
			oc get all
		else
			#oc create -n $PROJECT -f build.yaml
			oc get all
		fi
		BUILDNUBER=$(oc -n $PROJECT start-build ${PROJECT} | cut -d'"' -f2)
		echo "The build job is" $BUILDNUBER
		until [ "$BUILDSTATUS" == "Failed" ] || [ "$BUILDSTATUS" == "Complete" ] ; do
			BUILDSTATUS=$(oc -n $PROJECT get build/$BUILDNUBER -o jsonpath={.status.phase})
			echo $BUILDNUBER status is $BUILDSTATUS
			sleep 5
		done
		if [ "$BUILDSTATUS" == "Failed" ]; then echo "Oops, build failed!"; exit 1; fi
		if [ "$BUILDSTATUS" == "Complete" ]; then 
			echo "Congrats! build completed!"; 
			#oc -n $PROJECT tag ${PROJECT}:${VERSION} $PROJECT:latest
			exit 0;
			 fi
		;;
	deploy)
		if [ -z ${VERSION} ] || [ -z ${ENVIRONMENT} ]; then
			echo "You need to specify [which version] to deploy to [which environment]!"
			echo "Usage: ./pipeline.sh deploy  "
			exit 1
		fi
		if [ "${VERSION}" == "latest" ]; then VERSION=$TAG; fi
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		echo "You are deploying version "$VERSION "to" $ENVIRONMENT
		#sed -e "s/%buildversion%/${VERSION}/g" -e "s/%imageversion%/${VERSION}/g" -e "s/%env%/${ENVIRONMENT}/g" deploy-template.yaml > deploy.yaml
		if [[ $(oc -n $PROJECT get dc | grep -c ${ENVIRONMENT}) -gt 0 ]]; then
		#	oc replace -n $PROJECT -f deploy.yaml
			echo deploy exists
		else
			echo deploy did nt exist
		#	oc create -n $PROJECT -f deploy.yaml
		fi
		#oc get dc/${ENVIRONMENT} -w -o jsonpath={.status.availableReplicas}
		;;
	*)
		echo 'Usage:'
		echo 'To build : ./pipeline.sh build [version]'
		echo 'To deploy: ./pipeline.sh deploy  '
		echo 'To CI/CD: ./pipeline.sh build && ./pipeline.sh deploy latest '
		exit 1		
		;;
esac		

# Create pipeline demo projects in thie cluster
#oc new-project ci-cd
oc new-project viaa-elk --display-name="Elastic Search" || true

# Switch to the cicd and create the pipeline build from a template
oc project ci-cd
## setup pipeline

oc apply -f pipeline_git.yaml
# Give this project an edit role on other related projects
oc policy add-role-to-user edit system:serviceaccount:ci-cd:jenkins -n viaa-elk
#oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n pipeline-app-staging

# Give the other related projects the role to pull images from pipeline-app
#oc policy add-role-to-group system:image-puller system:serviceaccounts:pipeline-app-staging -n pipeline-app

# Wait for Jenkins to start
oc project ci-cd
echo "Waiting for Jenkins pod to start.  You can safely exit this with Ctrl+C or just wait."
until 
	oc get pods -l name=jenkins | grep -m 1 "Running"
do
	oc get pods -l name=jenkins
	sleep 2
done
echo "Yay, Jenkins is ready."
echo "But we need to do one more thing because of a current limitation."
echo "From the CI/CD project - open the Jenkins webconsole, Manage Jenkins->Configure System->OpenShift Jenkins Sync->Namespace and add 'viaa-elk' to the list"
echo ""
echo "Then you can start your pipeline with:"
echo "> oc start-build -F viaa-elk"
oc project viaa-elk
oc create sa filebeat metricbeat
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:filebeat
oc patch namespace viaa-elk -p '{metadata: {annotations: {openshift.io/node-selector: }}}'
oc adm policy add-scc-to-user privileged system:serviceaccount:viaa-elk:filebeat
oc adm policy add-scc-to-user privileged system:serviceaccount:viaa-elk:metricbeat


TOKEN=$(oc whoami -t)
ENDPOINT=$(oc config current-context | cut -d/ -f2 | tr - .)
NAMESPACE=$(oc config current-context | cut -d/ -f1)

def TEMPLATEPATH = 'https://raw.githubusercontent.com/viaacode/viaa-elk/master/elk-cluster-tmpl.yaml'
def TEMPLATENAME = 'es-cluster-prd'
def TARGET_NS = 'viaa-elk'
def templatePath = 'https://raw.githubusercontent.com/viaacode/viaa-elk/master/elk-cluster-tmpl.yaml'
def initTemplatePath = 'https://raw.githubusercontent.com/viaacode/viaa-elk/master/es-int-tmp.yaml'
// NOTE, the "pipeline" directive/closure from the declarative pipeline syntax needs to include, or be nested outside,
// and "openshift" directive/closure from the OpenShift Client Plugin for Jenkins.  Otherwise, the declarative pipeline engine
// will not be fully engaged.
pipeline {
    agent {
      node {
        // spin up a pod to run this build on
        label 'master'
      }
    }
    options {
        // set a timeout of 20 minutes for this pipeline
        timeout(time: 20, unit: 'MINUTES')
    }
    stages {
        stage('preamble') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("viaa-elk") {
                            echo "Using project: ${openshift.project()}"
                        }
                    }
                }
            }
        }
        stage('cleanup') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("viaa-elk") {
                            // delete everything with this template label
			    if (openshift.selector("template", "es-int").exists()) {
				    echo "init tmpl exists"
				    openshift.selector("all", [ template : "es-init" ]).delete()

			    }
                            //openshift.selector("all", [ statefulset  : TEMPLATENAME ]).delete()
                            sh '''#!/bin/bash

			     #oc delete all --selector=ENV=prd || true
			    # oc delete all --selector=ENV=prd,app=elastic-prd || echo "NOthing Deleted"
			     sleep 10
			   # for pod in $(oc -n viaa-elk get pods | grep Error | awk '{print $1}'); do oc delete pod --grace-period=1 ${pod}; done

                            '''
                        }
                    }
                } // script
            } // steps
        } // stage
 stage('create') {
      steps {
        script {
            openshift.withCluster() {
                openshift.withProject("viaa-elk") {
			echo "newAPP"
                 // openshift.newApp(initTemplatePath)
                }
            }
        }
      }
    }


        stage('create2') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("viaa-elk") {
                            // create a new application from the TEMPLATEPATH
                           // openshift.newApp(TEMPLATEPATH)
                           sh "oc -n viaa-elk apply -f elk-cluster-tmpl.yaml"
                           echo "processing WARNING need root container for build"
                            sh '''#!/bin/bash

                                  oc project viaa-elk
                                 # oc -n viaa-elk delete all --selector=component=elasticsearch-prd
                                  # oc -n viaa-elk delete  configmap --selector=ENV=prd
                                  oc -n viaa-elk  get templates
                                  #oc -n viaa-elk  delete statefulset es-cluster-prd
                                  #oc -n viaa-elk adm policy add-scc-to-user privileged -n viaa-elk -z default
                                  #oc -n viaa-elk process viaa-elk -l app=es-pipe ENV=prd | oc apply -f -
                               '''
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('build_es_images') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("viaa-elk") {
                             echo "Start the docker build for ES"
                             sh '''#!/bin/bash
                             oc project viaa-elk
                              # oc adm policy add-scc-to-user privileged system:serviceaccount:viaa-elk:default --as system:admin --as-group system:admins -n viaa-elk
                          #    oc -n viaa-elk delete imagestreamtag.image.openshift.io "elastic-prd:7.1.0" || true
                              #oc -n viaa-elk delete buildconfigs.build.openshift.io "elastic-prd-1" || true
                              oc -n viaa-elk start-build -w elastic-prd || oc -n viaa-elk new-build --name=elastic-prd --strategy=docker  .
                             '''
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('Follow Build') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("viaa-elk") {
                            echo "Get build and follow the output"
                            sh '''#!/bin/bash
                            echo building starts ...
                            oc -n viaa-elk get builds
                            oc -n viaa-elk logs -f bc/elastic-prd
                            echo Building finished exitcode $?

                            '''

                        }
                    }


                } // script

            } // steps
        } // stage




               stage('Roll out') {
            steps {
        //    input message: "Deploy Test cluster?: es-prd. Approve?", id: "approval"

                script {
                    openshift.withCluster() {
                        openshift.withProject("viaa-elk") {
                             echo "Rolling out  build from template"
                             sh '''#/bin/bash
                             echo Rolling out the prd cluster
			                       oc process -p ENV=prd -l app=elastic-prd -l ENV=prd -f es-int-tmp.yaml | oc apply -f -
                             oc process  -p DISKSIZE=90Gi  -p ENV=prd -l app=elastic-prd -l ENV=prd  -f ./elk-cluster-tmpl.yaml | oc apply -f -
	                        #   oc process -f filebeat-ds.yaml -l ENV=prd,app=elastic-prd | oc apply -f -
                             '''
                        }
                    }
                } // script
            } // steps
        } // stage

               stage('Tag') {
            steps {

                script {
                    openshift.withCluster() {
                        openshift.withProject("viaa-elk") {
                             echo "Rolling out  build from template"
                             sh '''#!/bin/bash
                              oc  -n viaa-elk tag  elastic-prd:latest  es-prd:7.1.0
                              oc  -n viaa-elk tag  elastic-prd:latest  es-qas:latest
			      oc  -n viaa-elk tag  elastic-prd:latest  es-prd:latest
                             '''
                        }
                    }
                } // script
            } // steps
        } // stag
    } // stages
} // pipeline

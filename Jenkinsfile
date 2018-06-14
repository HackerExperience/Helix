node('master') {
  stage('Setup'){
    WS_PATH = sh(script: 'pwd', returnStdout: true).trim()
    BUILD_VERSION = sh(script: 'date +%Y.%m.%d%H%M', returnStdout: true).trim()
    TAG=sh(script: 'pwgen 5 1', returnStdout: true).trim()
    sh "python3.6 ~/start.py utils small-1 ${TAG} 15"
    sh "python3.6 ~/start.py helix large-1 ${TAG} 15"
    sh "python3.6 ~/start.py helix large-2 ${TAG} 15"
  }
}

pipeline {
  agent none
  options {
    skipDefaultCheckout()
  }
  stages {
    stage("Checkout") {
      agent {
        node {
          label "utils-small-1-${TAG}"
        }
      }
      steps {
        checkout scm

        sh 'mix local.hex --force'
        sh 'mix local.rebar --force'
        sh 'mix clean'
        sh 'mix deps.get'

        stash name: 'source', useDefaultExcludes: false
      }
    }
    stage('Build:') {
      parallel {
        stage('Test') {
          agent {
            node {
              label "helix-large-1-${TAG}"
            }
          }
          environment {
            MIX_ENV='test'
          }
          steps {
            unstash 'source'
            sh 'mix compile'

            stash name: 'build-test', useDefaultExcludes: false
          }
        }
        stage('Prod') {
          agent {
            node {
              label "helix-large-2-${TAG}"
            }
          }
          environment {
            MIX_ENV='prod'
          }
          steps {
            unstash 'source'
            sh 'mix compile'
            stash name: 'build-prod', useDefaultExcludes: false
          }
        }
      }
    }
    stage('Verify:') {
      parallel {
        stage('Syntax') {
          agent {
            node {
              label "utils-small-1-${TAG}"
            }
          }
          environment {
            MIX_ENV='test'
          }
          steps {
            cleanWs()
            unstash 'build-test'

            sh 'mix credo --strict'
          }
        }
        stage('Tests') {
          agent {
            node {
              label "helix-large-1-${TAG}"
            }
          }
          environment {
            MIX_ENV='test'
            HELIX_SKIP_WARNINGS='false'
            HELIX_TEST_ENV='jenkins'
          }
          steps {
            cleanWs()
            unstash 'build-test'

            sh '#!/bin/sh -e\n' + '. ~/.profile && mix test.full'
          }
        }
        stage('Types') {
          agent {
            node {
              label "helix-large-2-${TAG}"
            }
          }
          environment {
            MIX_ENV='prod'
          }
          steps {
            cleanWs()
            unstash 'build-prod'

            sh "python3.6 ~/load_plt.py /usr/home${WS_PATH}"
            sh 'mix dialyzer --halt-exit-status'
            sh "python3.6 ~/save_plt.py /usr/home${WS_PATH}"
          }
        }
      }
    }
  }
  post {
    always {
      node('master') {
        sh "python3.6 ~/stop.py ${TAG}"
      }
    }
  }
}

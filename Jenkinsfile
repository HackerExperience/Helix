#!/usr/bin/env groovy

env.BUILD_VERSION = sh(scrit: 'date +%Y.%m.%d%H%M', returnStdout: true).trim()
def ARTIFACT_PATH = "env.BRANCH_NAME + '/' + env.BUILD_VERSION" 
println ${ARTIFACT_PATH}

node('elixir') {

  stage('Pre-build') {
    env.BUILD_VERSION = sh(script: 'date +%Y.%m.%d%H%M', returnStdout: true).trim()
    def ARTIFACT_PATH = "${env.BRANCH_NAME}/${env.BUILD_VERSION}"

    checkout scm
  }

  stage('Build') {
    sh 'env | sort'
    sh 'mix local.hex --force'
    sh 'mix local.rebar --force'
    sh 'mix clean'
    sh 'mix deps.get'

    withEnv (['MIX_ENV=prod']) {
      sh 'mix release --env=prod'
    }

    // Stash artifacts
    stash excludes: '_build/', '.git', includes: '**', name: 'source'
  }
}

parallel (
  node('elixir') {
    stage('Lint') {
      unstash 'source'
      //sh "mix credo"
    }
  },
  node('elixir') {
    stage('Unit tests') {
      unstash 'source'
      //sh "mix test --only unit"
    }
  },
  node('elixir') {
    stage('Type validation') {
      unstash 'source'
      //sh "dialyzer"
    }
  }
)

node('helix') {
  stage('Integration tests') {
    unstash 'source'
    //sh 'mix test --only integration'
  }
}

node('elixir') {
  if (env.BRANCH_NAME == 'master'){
    lock(resource: 'production-deployment', inversePrecedence: true) {
      stage('Deploy') {
        sh "ssh deployer deploy helix prod --branch master --version env.BUILD_VERSION"
      }
    }
    milestone()
  }
}

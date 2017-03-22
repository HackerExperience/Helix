#!/usr/bin/env groovy

node('elixir') {

  stage('Pre-build') {
    env.BUILD_VERSION = sh(script: 'date +%Y.%m.%d%H%M', returnStdout: true).trim()
    def ARTIFACT_PATH = "${env.BRANCH_NAME}/${env.BUILD_VERSION}"

    checkout scm
  }

  stage('Build') {
    sh 'mix local.hex --force'
    sh 'mix local.rebar --force'
    sh 'mix clean'
    sh 'mix deps.get'

    withEnv (['MIX_ENV=prod']) {
      sh 'mix release --env=prod --warnings-as-errors'
    }

    // Stash artifacts
    stash excludes: '_build/, .git', includes: '**', name: 'source'
    stash excludes: '*', includes: "_build/prod/rel/helix/releases/**/helix.tar.gz", name: 'release'
  }
}

parallel (
  'Lint': {
    node('elixir') {
      stage('Lint') {
        unstash 'source'
        sh "mix credo --strict"
      }
    }
  },
  'Unit tests': {
    node('elixir') {
      stage('Unit tests') {
        unstash 'source'
        //sh "mix test --only unit"
      }
    }
  },
  'Type validation': {
    node('elixir') {
      stage('Type validation') {
        unstash 'source'

        withEnv (['MIX_ENV=prod']) {
          sh "mix clean"
          sh "mix compile"
          sh "mix dialyzer --halt-exit-status"
        }
      }
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

  stage('Save artifacts') {

    unstash 'release'
    sh "aws s3 cp _build/prod/rel/helix/releases/*/helix.tar.gz s3://he2-releases/helix/${env.BRANCH_NAME}/${env.BUILD_VERSION}.tar.gz --storage-class REDUCED_REDUNDANCY"

  }

  if (env.BRANCH_NAME == 'master'){
    lock(resource: 'production-deployment', inversePrecedence: true) {
      stage('Deploy') {
        sh "ssh deployer deploy helix prod --branch master --version ${env.BUILD_VERSION}"
      }
    }
    milestone()
  }
}

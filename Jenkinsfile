#!/usr/bin/env groovy

retry(2) {
  node('elixir') {
    stage('Pre-build') {
      step([$class: 'WsCleanup'])

      env.BUILD_VERSION = sh(script: 'date +%Y.%m.%d%H%M', returnStdout: true).trim()
      def ARTIFACT_PATH = "${env.BRANCH_NAME}/${env.BUILD_VERSION}"

      checkout scm

      sh 'mix local.hex --force'
      sh 'mix local.rebar --force'
      sh 'mix clean'
      sh 'mix deps.get'

      stash name: 'source', useDefaultExcludes: false
    }
  }

  node('elixir') {
    stage('Build [test]') {
      timeout(3) {
        step([$class: 'WsCleanup'])

        unstash 'source'

        withEnv (['MIX_ENV=test']) {
          sh 'mix compile'
        }

        stash 'build-test'
      }
    }
  }

  node('elixir') {
    stage('Build [prod]') {
      timeout(3) {
        step([$class: 'WsCleanup'])

        unstash 'source'

        withEnv (['MIX_ENV=prod']) {
          sh 'mix compile'
          sh 'mix release --env=prod --warnings-as-errors'
        }

        stash 'build-prod'
      }
    }
  }

  parallel (
    'Lint': {
      node('elixir') {
        stage('Lint') {
          timeout(3) {
            step([$class: 'WsCleanup'])

            unstash 'source'
            unstash 'build-test'

            withEnv (['MIX_ENV=test']) {
              sh 'mix credo --strict'
            }
          }
        }
      }
    },
    'Type validation': {
      node('elixir') {
        stage('Type validation') {
          timeout(3) {
            step([$class: 'WsCleanup'])

            unstash 'build-prod'

            // HACK: mix complains if I don't run deps.get again, not sure why
            sh 'mix deps.get'

            // Reuse existing plt
            sh 'cp ~/.mix/*prod*.plt* _build/prod || :'

            withEnv (['MIX_ENV=prod']) {
              sh 'mix dialyzer --halt-exit-status'
            }

            // Store newly generated plt
            // Do it on two commands because we want it failing if .plt is not found
            sh 'cp _build/prod/*.plt ~/.mix/'
            sh 'cp _build/prod/*.plt.hash ~/.mix/'
          }
        }

      }
    },
    'Tests': {
      node('helix') {
        stage('Tests') {
          timeout(3) {
            step([$class: 'WsCleanup'])

            unstash 'source'
            unstash 'build-test'

            withEnv (['MIX_ENV=test']) {
              // HACK: mix complains if I don't run deps.get again, not sure why
              sh 'mix deps.get'

              // Unset debug flag, load env vars on ~/.profile & run mix test
              sh '#!/bin/sh -e\n' + '. ~/.profile && mix test.full'
            }
          }
        }
      }
    }
  )

  node('elixir') {

    stage('Save artifacts') {
      step([$class: 'WsCleanup'])

      unstash 'build-prod'

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
}
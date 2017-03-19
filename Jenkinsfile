#!/usr/bin/env groovy

node('elixir') {
  stage('Build') {
    env.TEST = "test"
    checkout scm
    sh 'env > env.txt'
    sh "mix local.hex --force"
    sh "mix local.rebar --force"
    sh "mix clean"
    sh "mix deps.get"
    
    sh "MIX_ENV=prod && mix release --env=prod"

    // Stash artifacts
    stash excludes: '_build/', includes: '**', name: source
    stash includes: '_build/prod/rel/helix/releases/0.1.0/helix.tar.gz', name: release
  }
}

parallel (
  node('elixir') {
    stage('Lint') {
      unstash source
      //sh "mix credo"
    }
  },
  node('elixir') {
    stage('Unit tests') {
      unstash source
      //sh "mix test --only unit"
    }
  },
  node('elixir') {
    stage('Type validation') {
      unstash source
      //sh "dialyzer"
    }
  }
)

node('helix') {
  stage('Integration tests') {
    unstash source
    //sh "mix test --only integration"
  }
}

if (env.BRANCH_NAME == 'master'){
  lock(resource: 'production-deployment', inversePrecedence: true){
    node('elixir') {
      stage('Deploy') {
        sh "ssh deployer deploy helix prod --branch master"
      }
    }
    milestone()
  }
}


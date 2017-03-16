node('elixir') {
  stage('Build') {
    checkout scm
    sh 'env > env.txt'
    sh "mix local.hex --force"
    sh "mix local.rebar --force"
    sh "mix clean"
    sh "mix deps.get"
    sh "mix compile"
  }

  stage('Lint') {
    #sh "mix credo"
  }
  stage('Unit Tests') {
    #sh "mix test --only unit"
  }

  stage('Type spec validation') {
    #sh "dialyzer"
  }
}
node('helix') {

  # Make a node with pg support and liga o fodase
  stage('Integration tests') {
    #sh "mix test --only integration"
  }
}
node('elixir') {
  stage('Deploy') {
    if (env.BRANCH_NAME == 'master'){
      sh "ls"
    } else {
      echo 'lol'
    }
  }
}


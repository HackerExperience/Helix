node('elixir') {
  stage('Build') {
    checkout scm
    sh "mix local.hex --force"
    sh "mix local.rebar --force"
    sh "mix clean"
    sh "mix deps.get"
    sh "mix compile"
  }

  stage('Lint') {
    sh "mix credo"
  }

  stage('Test') {
    sh "mix test"
  }
}


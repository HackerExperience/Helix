<p align="center"><img src="help/logo.png" /></p>


# Helix [![Build Status](https://ci.hackerexperience.com/buildStatus/icon?job=HackerExperience/Helix/master)](https://ci.hackerexperience.com/job/HackerExperience/job/Helix/job/master) [![Ebert](https://ebertapp.io/github/HackerExperience/Helix.svg)](https://ebertapp.io/github/HackerExperience/Helix) ![](https://tokei.rs/b1/github/hackerexperience/helix) [![Coverage Status](https://coveralls.io/repos/github/HackerExperience/Helix/badge.svg?branch=master)](https://coveralls.io/github/HackerExperience/Helix?branch=master)
---

Helix is the backend powering the game **Hacker Experience 2**.

## Building a release
To build a release, run the following command

```
MIX_ENV=prod mix do deps.get, compile, release --env=prod
```

This will generate a release on `_build/prod/rel/helix`

To run the output release, export the environment variables specified on this
README along with the env `REPLACE_OS_VARS=true` and execute the
`_build/prod/rel/helix/bin/helix console`*

Note that if this is the first time you are running the helix server, you have
to first properly create the database and populate it using `helix ecto_create`,
`helix ecto_migrate` and `helix seeds`

**Example:**
```
export HELIX_CLUSTER_COOKIE=randomcookie
export HELIX_NODE_NAME=mynode
export HELIX_ENDPOINT_SECRET_KEY=reallyreallylongstring
export HELIX_ENDPOINT_URL=127.0.0.1
export HELIX_DB_USER=postgres
export HELIX_DB_PASS=postgres
export HELIX_DB_HOST=localhost
export HELIX_DB_PREFIX=helix
export HELIX_DB_POOL_SIZE=3
export HELIX_SSL_KEYFILE=priv/dev/ssl.key
export HELIX_SSL_CERTFILE=priv/dev/ssl.crt
export HELIX_MIGRATION_TOKEN=foobar

REPLACE_OS_VARS=true _build/prod/rel/helix/bin/helix ecto_create
REPLACE_OS_VARS=true _build/prod/rel/helix/bin/helix ecto_migrate
REPLACE_OS_VARS=true _build/prod/rel/helix/bin/helix seeds
REPLACE_OS_VARS=true _build/prod/rel/helix/bin/helix console
```

**Notes**

\* `helix console` will run the application in the _interactive_ mode, that way
you can execute elixir code on the terminal. You can alternatively use
`helix foreground` to run it on foreground (but without the interactive io) or
`helix start` to run it on background

## Environment variables

| Environment | Required? | Example Value | Description |
|:-- |:--:|:-- |:-- |
|`HELIX_CLUSTER_COOKIE`| ✓ | randomcookie | The secret cookie used to authenticate erlang nodes on a cluster* |
|`HELIX_NODE_NAME`| ✓ | mynode | Each erlang node on a cluster must have a different name; this name is used solely to identify the node on the cluster |
|`HELIX_ENDPOINT_SECRET_KEY`| ✓ | reallyreallylongstring | The secret key used to encrypt the session token |
|`HELIX_ENDPOINT_URL`| ✓ | 127.0.0.1 | The hostname where the Helix server will run |
|`HELIX_DB_USER`| ✓ | postgres | RDBMS username |
|`HELIX_DB_PASS`| ✓ | postgres | RDBMS password |
|`HELIX_DB_HOST`| ✓ | localhost | RDBMS hostname |
|`HELIX_DB_PREFIX`| ✓ | helix | The prefix for the databases used on Helix. Eg: if the prefix is `foobar`, the database for accounts will be `foobar_prod_account` |
|`HELIX_DB_POOL_SIZE`| ✓ | 3 | The amount of connections constantly open for each database |
|`HELIX_SSL_KEYFILE`| ✓ | priv/dev/ssl.key | The path for the keyfile used on HTTPS connections |
|`HELIX_SSL_CERTFILE`| ✓ | priv/dev/sll.crt | The path for the certificate used on HTTPS connections |
|`HELIX_MIGRATION_TOKEN`| ✕ | foobar | Token used to authenticate HEBornMigration application exports |
|`APPSIGNAL_PUSH_API_KEY`| ✕ | abcdef | Key for AppSignal. If this env is not provided, AppSignal won't log errors |

**Notes**

\* Note that the secret cookie is the only authentication (besides your firewall) that erlang provides to avoid another erlang node to take direct root access into your server so this cookie should be secure enough and your firewall should be properly configured, otherwise your server is prone to real danger (again, erlang provides root access to the server)


## Support
You can get support on shipping your community release on our [Online Chat](https://chatops.hackerexperience.com/).

If you have any question that could not be responded on the chat by our
contributors, feel free to open an issue.

## License
Hacker Experience 2, "Helix" and the Hacker Experience 2 logo are copyright (c)
2015-2017 Neoart Labs LLC.

Helix source code is released under AGPL 3.

Check [LICENSE](LICENSE) or [GNU AGPL3](https://www.gnu.org/licenses/agpl-3.0.en.html)
for more information.

[![AGPL3](https://www.gnu.org/graphics/agplv3-88x31.png)](https://www.gnu.org/licenses/agpl-3.0.en.html)

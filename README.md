# Renovate approve bot

Bot to approve pull requests made by [Renovate](https://docs.renovatebot.com/) in Forgejo/Gitea.

[![pulls](https://img.shields.io/docker/pulls/kokuwaio/renovate-approve-bot)](https://hub.docker.com/r/kokuwaio/renovate-approve-bot)
[![size](https://img.shields.io/docker/image-size/kokuwaio/renovate-approve-bot)](https://hub.docker.com/r/kokuwaio/renovate-approve-bot)
[![dockerfile](https://img.shields.io/badge/source-Dockerfile%20-blue)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/src/branch/main/Dockerfile)
[![license](https://img.shields.io/badge/License-EUPL%201.2-blue)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/src/branch/main/LICENSE)
[![prs](https://img.shields.io/gitea/pull-requests/open/kokuwaio/renovate-approve-bot?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/pulls)
[![issues](https://img.shields.io/gitea/issues/open/kokuwaio/renovate-approve-bot?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/issues)

## Configuration

```text
Bot to approve pull requests made by Renovate in Forgejo/Gitea.

Usage: 

Options:
      --host <HOST>
          Host of forge
      --token-file <token-file>
          File with forgen token
      --repository-topic <REPOSITORY_TOPIC>
          Topic for repository search [default: renovate]
      --renovate-user <RENOVATE_USER>
          Username of renovate bot to identity pull requests to handle [default: renovate]
      --log-level <LOG_LEVEL>
          Log level [default: Info]
      --log-format <LOG_FORMAT>
          Log format [default: logfmt] [possible values: text, logfmt]
  -h, --help
          Print help
  -V, --version
          Print version
```

## Usage as Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: renovate-approve-bot
spec:
  schedule: 10 * * * *
  jobTemplate:
    metadata:
      labels:
        app.kubernetes.io/name: renovate-approve-bot
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            app.kubernetes.io/name: renovate-approve-bot
        spec:
          containers:
            - name: renovate-approve-bot
              image: kokuwaio/renovate-approve-bot:0.0.2
              imagePullPolicy: IfNotPresent
              args:
                - --host=https://git.example.org # or e.g. http://forgejo.dev.svc.cluster.local
                - --token-file=/run/secrets/token
                - --log-level=DEBUG
                - --log-format=logfmt
              volumeMounts:
                - name: token
                  mountPath: /run/secrets/token
                  subPath: token
                  readOnly: true
          volumes:
            - name: token
              secret:
                secretName: renovate-approve-bot
```

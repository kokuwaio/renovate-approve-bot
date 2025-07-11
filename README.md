# Renovate approve bot for Forgejo/Gitea

This bot approves PRs created by [Renovate](https://docs.renovatebot.com/).

[![pulls](https://img.shields.io/docker/pulls/kokuwaio/renovate-approve-bot)](https://hub.docker.com/r/kokuwaio/renovate-approve-bot)
[![size](https://img.shields.io/docker/image-size/kokuwaio/renovate-approve-bot)](https://hub.docker.com/r/kokuwaio/renovate-approve-bot)
[![dockerfile](https://img.shields.io/badge/source-Dockerfile%20-blue)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/src/branch/main/Dockerfile)
[![license](https://img.shields.io/badge/License-EUPL%201.2-blue)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/src/branch/main/LICENSE)
[![prs](https://img.shields.io/gitea/pull-requests/open/kokuwaio/renovate-approve-bot?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/pulls)
[![issues](https://img.shields.io/gitea/issues/open/kokuwaio/renovate-approve-bot?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/kokuwaio/renovate-approve-bot/issues)

## Configuration

```text
Renovate approve bot for Forgejo/Gitea.

Usage: 

Options:
      --host <HOST>
          Host of forge
      --token-file <token-file>
          File with forgen token
      --repository-topic <repository-topic>
          Topic for repository search [default: renovate]
      --renovate-user <renovate-user>
          Username of renovate bot to identity pull requests to handle [default: renovate]
  -h, --help
          Print help
  -V, --version
          Print version
```

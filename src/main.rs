mod configuration;
mod forgejo;

use crate::configuration::Configuration;
use crate::forgejo::ForgejoClient;
use crate::forgejo::PullRequest;
use crate::forgejo::Repository;
use clap::Parser;
use env_logger::Builder;
use log::debug;
use log::info;
use std::io::Write;
use std::time::SystemTime;
use std::time::UNIX_EPOCH;

fn main() {
    let configuration = Configuration::parse();
    init_logging(&configuration);

    let token = std::fs::read_to_string(&configuration.token_file).unwrap();
    let client = ForgejoClient::new(configuration.host.clone(), token);
    let version = client.get_version().version;
    let username = client.get_authenticated_user().username;
    info!(
        "Forge at {} has version {}, using {} as username",
        &configuration.host, version, username
    );

    let repositories = client
        .get_repositories(&configuration.repository_topic)
        .data;
    debug!(
        "Found {} repositories with topic {}",
        repositories.len(),
        configuration.repository_topic
    );

    for repository in repositories {
        if repository.open_pr_counter == 0 {
            debug!("{} ignored because no open pr found", repository.full_name);
            continue;
        }
        let pull_requests =
            client.get_pull_requests(&repository.full_name, &configuration.renovate_user);
        debug!(
            "{} has {} pull requests with author {}",
            repository.full_name,
            pull_requests.len(),
            configuration.renovate_user
        );
        for pull_request in pull_requests {
            handle_pull_request(&client, &repository, &pull_request);
        }
    }
}

fn init_logging(configuration: &Configuration) {
    let mut builder = Builder::new();
    builder.filter_level(configuration.log_level);
    if configuration.log_format == "logfmt" {
        builder.format(|buf, record| {
            writeln!(
                buf,
                "ts={} log={} lvl={} msg=\"{}\"",
                SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap()
                    .as_millis(),
                record.metadata().target(),
                record.level(),
                record.args()
            )
        });
    }
    builder.init();
}

fn handle_pull_request(
    client: &ForgejoClient,
    repository: &Repository,
    pull_request: &PullRequest,
) {
    let reviews = client.get_reviews(&repository.full_name, &pull_request.number);
    debug!(
        "{}#{} has {} reviews",
        repository.full_name,
        pull_request.number,
        reviews.len()
    );

    for review in reviews {
        if review.dismissed {
            debug!(
                "{}#{} review {} from {} was dismissed",
                repository.full_name, pull_request.number, review.id, review.user.username,
            );
            continue;
        }
        if review.state == "APPROVED" {
            debug!(
                "{}#{} review {} from {} already approved this pull request ignored",
                repository.full_name, pull_request.number, review.user.username, review.state
            );
            return;
        }
    }

    client.approve_pull_request(&repository.full_name, &pull_request.number);
    info!("{}#{} approved", repository.full_name, pull_request.number);
}

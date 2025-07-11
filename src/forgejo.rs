use reqwest::blocking::Client;
use reqwest::header::ACCEPT;
use reqwest::header::AUTHORIZATION;
use reqwest::header::CONTENT_TYPE;
use reqwest::header::HeaderMap;
use reqwest::header::HeaderValue;
use serde::Deserialize;
use serde::de::DeserializeOwned;
use std::time::Duration;

/*
 * API
 */

static APP_USER_AGENT: &str = concat!(env!("CARGO_PKG_NAME"), "/", env!("CARGO_PKG_VERSION"));

pub struct ForgejoClient {
    client: Client,
    host: String,
}

impl ForgejoClient {
    pub fn new(host: String, token: String) -> ForgejoClient {
        let mut authorization = HeaderValue::from_str(&format!("token {}", token.trim())).unwrap();
        authorization.set_sensitive(true);

        let mut headers = HeaderMap::new();
        headers.insert(AUTHORIZATION, authorization);
        headers.insert(ACCEPT, HeaderValue::from_static("application/json"));

        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .user_agent(APP_USER_AGENT)
            .default_headers(headers)
            .build()
            .unwrap();

        ForgejoClient { client, host }
    }

    pub fn get_version(&self) -> Version {
        self.get(format!("{}/api/v1/version", self.host))
    }

    pub fn get_authenticated_user(&self) -> User {
        self.get(format!("{}/api/v1/user", self.host))
    }

    pub fn get_repositories(&self, topic: &str) -> RepositoryPage {
        self.get(format!(
            "{}/api/v1/repos/search?q={}&topic=true&archived=false&sort=updated&limit=100",
            self.host, topic
        ))
    }

    pub fn get_pull_requests(&self, repository: &str, username: &str) -> Vec<PullRequest> {
        self.get(format!(
            "{}/api/v1/repos/{}/pulls?state=open&sort=recentupdate&poster={}&limit=1000",
            self.host, repository, username
        ))
    }

    pub fn get_reviews(&self, repository: &str, number: &u16) -> Vec<PullRequestReview> {
        self.get(format!(
            "{}/api/v1/repos/{}/pulls/{}/reviews?limit=1000",
            self.host, repository, number
        ))
    }

    pub fn approve_pull_request(&self, repository: &str, number: &u16) {
        let response = self.client
            .post(format!(
                "{}/api/v1/repos/{}/pulls/{}/reviews",
                self.host, repository, number
            ))
            .header(CONTENT_TYPE, "application/json")
            .body("{\"event\":\"APPROVED\"}")
            .send()
            .unwrap();
        assert_eq!(response.status(), 200);
    }

    fn get<T: DeserializeOwned>(&self, url: String) -> T {
        let response = self.client.get(url).send().unwrap();
        assert_eq!(response.status(), 200);
        response.json::<T>().unwrap()
    }
}

/**
 * Models
 */

#[derive(Deserialize)]
pub struct Version {
    pub version: String,
}

#[derive(Deserialize)]
pub struct User {
    pub username: String,
}

#[derive(Deserialize)]
pub struct RepositoryPage {
    pub data: Vec<Repository>,
}

#[derive(Deserialize)]
pub struct Repository {
    pub full_name: String,
    pub open_pr_counter: u8,
}

#[derive(Deserialize)]
pub struct PullRequest {
    /// Repo specific ID displayed in Forge
    pub number: u16,
}
#[derive(Deserialize)]
pub struct PullRequestReview {
    pub id: u32,
    pub user: User,
    pub state: String,
    pub dismissed: bool,
}

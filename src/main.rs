mod configuration;

use crate::configuration::Configuration;
use clap::Parser;
use simple_logger::SimpleLogger;

fn main() {
    SimpleLogger::new().init().unwrap();

    let configuration = Configuration::parse();
    let token = std::fs::read_to_string(&configuration.token_file).unwrap();

    log::info!("Host:  {}", configuration.host);
    log::info!("Token: {}", token);
}

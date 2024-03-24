use poise::serenity_prelude as serenity;
use std::env;

use dotenv::dotenv;

struct Data {}
type Error = Box<dyn std::error::Error + Send + Sync>;

#[tokio::main]
async fn main() {
    dotenv().ok();
    env_logger::init();
    let token = env::var("DISCORD_TOKEN").expect("Expected a token in the environment");
    let intents = serenity::GatewayIntents::non_privileged();

    let framework = poise::Framework::<Data, Error>::builder()
        .options(poise::FrameworkOptions {
            commands: vec![],
            ..Default::default()
        })
        .setup(|ctx, _ready, framework| {
            Box::pin(async move {
                poise::builtins::register_globally(ctx, &framework.options().commands).await?;
                Ok(Data {})
            })
        })
        .build();

    let client = serenity::ClientBuilder::new(token, intents)
        .framework(framework)
        .await;

    client.unwrap().start().await.unwrap();
}

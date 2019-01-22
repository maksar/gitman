# Gitman

## Description

Gitman is a Telegram chat bot. It simplifies creation of repositories on Itransition Bitbucket server.

What Gitman can do:
* Create projects and repositories.
  * Give project's development group access to the source code repository.
  * Add technical coordinator admin access to the source code repository.
* Modify pull requests merging rules:
  * Enforce minimal approvals check.
  * Enforce minimal successful builds check.
  * Assign members of the development group as default reviewers.
* Configure default branching model of the source code repository:
  * Set recommended settings for the default branch names.
  * Enforce usage of pull requests to push changes.
* Enable popular Bitbucket features:
  * Turn on git LFS (Large Files Support) feature.
  * Turn on force push prohibition.
* Install various push hooks:
  * Verification of the commit message to contain JIRA task key.
  * Requirement for the committer email and username to match Bitbucket user setting.

### Requirements

* Telegram account
* ruby 2.6
* `.env` with correct values for keys from `.env.sample`
* `users.yml` with correct values for allowed users from `users.yml.sample`

## Install

Telegram uses `@BotFather` bot to create and manage bots. `@itransition_gitman_bot` was created by such dialog:

    You:
        /newbot

    BotFather:
        Alright, a new bot. How are we going to call it? Please choose a name for your bot.

    You:
        Gitman

    BotFather:
        Good. Now let's choose a username for your bot. It must end in `bot`. Like this, for example: TetrisBot or tetris_bot.

    You:
        itransition_gitman_bot

    BotFather:
        Done! Congratulations on your new bot. You will find it at t.me/itransition_gitman_bot. You can now add a description, about section and profile picture for your bot, see /help for a list of commands. By the way, when you've finished creating your cool bot, ping our Bot Support if you want a better username for it. Just make sure the bot is fully operational before you do this.

        Use this token to access the HTTP API:
        GITMAN_TELEGRAM_TOKEN

        For a description of the Bot API, see this page: https://core.telegram.org/bots/api

    You:
        /setcommands

    BotFather:
        Choose a bot to change the list of commands.

    You:
        @itransition_gitman_bot

    BotFather:
        OK. Send me a list of commands for your bot. Please use this format:

        command1 - Description
        command2 - Another description

    You:
        create - Creates Bitbucket repository or changes it’s settings.

    BotFather:
        Success! Command list updated. /help

## Authentication

`users.yml` file contains list of allowed users in a format `Lastname, Firstname`. 
Bot will ask to send user's contact. Then it will check ActiveDirectory for user's fist and last name, phone number and uid (in `extensionAttribute10` field).
If everything matches, bot will store user in `users.yml` file and start talking to him. 

## Running

### Docker
    docker build -t gitman .
    docker run --rm --env-file .env -v $PWD/users.yml:/app/users.yml -it gitman ./server.rb

### Local
    source <(sed -r 's/([A-Z_]+)=(.*)/export \1="\2"/g' .env)
    ruby server.rb

## Running tests
    source <(sed -r 's/([A-Z_]+)=(.*)/export \1="\2"/g' .env)
    rubocop && deep-cover clone rspec -- && open coverage/index.html

## TODO
* disable branch deletion
* introduce namespaces
# Game Survey Samples

https://survey.hackberry.group

Samples to integrate HackBerry Game Survey into games for various engines.

# Overview

You will need your game's ID. Each game client needs a player ID. The player ID should be stored
on the player's device (and shared via cloud saves if enabled).

## Create player

To get a new player ID, make a `POST` request with no body to

`https://game.survey.hackberry.group/games/:gameID/players`

You should also set the `Content-Length` header to `0`.

A success will appear as:

```json
{ "playerId": "<player ID>" }
```

## Get new question

Once you have a player ID, you can request a survey question at any time by making another `POST`
request:

`https://game.survey.hackberry.group/players/:playerID/questions`

Again, the `Content-Length` header should be set to `0`.

The user may have been asked a question to recently (configurable through the UI).
If so, the response will be JSON `null`.

An error will be described with:

```json
{ "error": "<message>" }
```

A success will look like:

```json
{
    "responseId": "<response ID>",
    "prompt": "<prompt text to show player>",
    "choices": [
        "<choice 1>",
        "<choice 2>",
        ...
    ]
}
```

## Answer question

To answer a question, a `POST` request should be made. The request should have the header set for
`Content-Type: application/x-www-form-urlencoded`, and the body should be:

```
choice=0
```

The choice value should be 0-indexed.

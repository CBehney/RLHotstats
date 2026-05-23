# Rocket League Stats API

Developer reference for the Rocket League Game Data API (`MatchStatsExporter`). Enable via `DefaultStatsAPI.ini` before launching the client; the game opens a local socket that streams JSON messages during matches.

**Source:** [rocketleague.com/developer/stats-api](https://www.rocketleague.com/developer/stats-api)

---

## Overview

The Stats API broadcasts JSON messages over a local socket while a match is in progress. Messages are sent both at a configurable periodic rate and when specific match events occur. Event data is always emitted on the same tick that the event occurs, regardless of the user's `PacketSendRate`.

All configuration must be done **before** the client starts. Changes to the ini while the client is running require a restart.

### Field visibility

| Marker | Meaning |
| --- | --- |
| **CONDITIONAL** | Field is only present when relevant. |
| **SPECTATOR** | Field is only present if the client is spectating or on the player's team. |

### Common types

| Type | Description |
| --- | --- |
| `vector` | Object with `X`, `Y`, and `Z` float components (Unreal world units). |
| `bool` | Boolean. |
| `int` | Integer. |
| `float` | Floating-point number. |
| `string` | String. |
| `array` | JSON array. |
| `object` | JSON object. |

### MatchGuid

Present on most event payloads. Only set for online or LAN matches.

---

## Configuration

Edit `%USERPROFILE%\Documents\My Games\Rocket League\TAGame\Config\DefaultStatsAPI.ini` before launching the client.

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `PacketSendRate` | float | `0` (disabled) | Number of `UpdateState` packets broadcast per second. Must be greater than `0` to enable the socket. Capped at `120`. |
| `Port` | int | `49123` | Local port the socket listens on. |

---

## Message Format

Every message uses this envelope:

```json
{
  "Event": "EventName",
  "Data": { }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `Event` | string | Event name (e.g. `UpdateState`, `GoalScored`). |
| `Data` | object | Event-specific payload documented below. |

The stream is concatenated JSON objects (not newline-delimited). Consumers must frame individual messages from the TCP stream.

---

## Events

### UpdateState

Sent periodically at the rate configured by `PacketSendRate`. Provides a full snapshot of player stats and match state.

```json
{
  "Event": "UpdateState",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "Players": [
      {
        "Name": "PlayerA",
        "PrimaryId": "Steam|123|0",
        "Shortcut": 1,
        "TeamNum": 0,
        "Score": 125,
        "Goals": 1,
        "Shots": 2,
        "Assists": 0,
        "Saves": 1,
        "Touches": 14,
        "CarTouches": 3,
        "Demos": 0,
        "bHasCar": true,
        "Speed": 1200,
        "Boost": 45,
        "bBoosting": true,
        "bOnGround": true,
        "bOnWall": false,
        "bPowersliding": false,
        "bDemolished": true,
        "Attacker": {
          "Name": "PlayerB",
          "Shortcut": 2,
          "TeamNum": 1
        },
        "bSupersonic": true
      }
    ],
    "Game": {
      "Teams": [
        {
          "Name": "Blue",
          "TeamNum": 0,
          "Score": 1,
          "ColorPrimary": "0000FF",
          "ColorSecondary": "0000AA"
        }
      ],
      "TimeSeconds": 180,
      "bOvertime": false,
      "Frame": 120,
      "Elapsed": 50.2,
      "Ball": {
        "Speed": 850.5,
        "TeamNum": 0
      },
      "bReplay": false,
      "bHasWinner": true,
      "Winner": "Blue",
      "Arena": "Stadium_P",
      "bHasTarget": true,
      "Target": {
        "Name": "PlayerA",
        "Shortcut": 1,
        "TeamNum": 0
      }
    }
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |
| `Players` | array | One entry per player in the match. |
| `Players[].Name` | string | Display name. |
| `Players[].PrimaryId` | string | Platform identifier: `Platform\|Uid\|Splitscreen` (e.g. `Steam\|123\|0`, `Epic\|456\|0`). |
| `Players[].Shortcut` | int | Spectator shortcut number. |
| `Players[].TeamNum` | int | Team index (`0` = Blue, `1` = Orange). |
| `Players[].Score` | int | Total match score. |
| `Players[].Goals` | int | Goals scored this match. |
| `Players[].Shots` | int | Shot attempts this match. |
| `Players[].Assists` | int | Assists earned this match. |
| `Players[].Saves` | int | Saves made this match. |
| `Players[].Touches` | int | Total ball touches. |
| `Players[].CarTouches` | int | Touches by the car body (not the ball). |
| `Players[].Demos` | int | Demolitions inflicted. |
| `Players[].bHasCar` | bool | **SPECTATOR** — True if the player currently has a vehicle. |
| `Players[].Speed` | float | **SPECTATOR** — Vehicle speed in Unreal Units/second. |
| `Players[].Boost` | int | **SPECTATOR** — Boost amount `0`–`100`. |
| `Players[].bBoosting` | bool | **SPECTATOR** — True if the player is currently boosting. |
| `Players[].bOnGround` | bool | **SPECTATOR** — True if at least 3 wheels are touching the world. |
| `Players[].bOnWall` | bool | **SPECTATOR** — True if the vehicle is on a wall. |
| `Players[].bPowersliding` | bool | **SPECTATOR** — True if the player is holding handbrake. |
| `Players[].bDemolished` | bool | **SPECTATOR** — True if the vehicle is currently destroyed. |
| `Players[].bSupersonic` | bool | **SPECTATOR** — True if the vehicle is at supersonic speed. |
| `Players[].Attacker` | object | **CONDITIONAL** — Present only when demolished. Player who demolished this player. |
| `Players[].Attacker.Name` | string | Name of the demolishing player. |
| `Players[].Attacker.Shortcut` | int | Spectator shortcut of the attacker. |
| `Players[].Attacker.TeamNum` | int | Team index of the attacker. |
| `Game` | object | Match metadata. |
| `Game.Teams` | array | One entry per team, ordered by `TeamNum`. |
| `Game.Teams[].Name` | string | Team name. |
| `Game.Teams[].TeamNum` | int | Team index. |
| `Game.Teams[].Score` | int | Team goal count. |
| `Game.Teams[].ColorPrimary` | string | Hex color code (no `#`) for the team's primary color. |
| `Game.Teams[].ColorSecondary` | string | Hex color code for the team's secondary color. |
| `Game.TimeSeconds` | int | Seconds remaining in the match. |
| `Game.bOvertime` | bool | True if the match is in overtime. |
| `Game.Frame` | int | **CONDITIONAL** — Current frame number if a replay is active. |
| `Game.Elapsed` | float | **CONDITIONAL** — Seconds elapsed since game start if a replay is active. |
| `Game.Ball` | object | Current ball state. |
| `Game.Ball.Speed` | float | Current ball speed in Unreal Units/second. |
| `Game.Ball.TeamNum` | int | Index of the last team to touch the ball. `255` if the ball has not been touched. |
| `Game.bReplay` | bool | True if a goal replay or history replay is active. |
| `Game.bHasWinner` | bool | True if a team has won. |
| `Game.Winner` | string | Name of the winning team. Empty string if no winner yet. |
| `Game.Arena` | string | Asset name of the current map (e.g. `Stadium_P`). |
| `Game.bHasTarget` | bool | True if the client is currently viewing a specific vehicle. |
| `Game.Target` | object | **CONDITIONAL** — Player currently being viewed. Members are empty string or `0` if no spectator target. |
| `Game.Target.Name` | string | Name of the player being viewed. |
| `Game.Target.Shortcut` | int | Spectator shortcut of the viewed player. |
| `Game.Target.TeamNum` | int | Team index of the viewed player. |

---

### BallHit

Sent one frame after the ball is hit.

```json
{
  "Event": "BallHit",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "Players": [
      {
        "Name": "PlayerA",
        "Shortcut": 1,
        "TeamNum": 0
      }
    ],
    "Ball": {
      "PreHitSpeed": 0,
      "PostHitSpeed": 1450.2,
      "Location": {
        "X": -512,
        "Y": 100,
        "Z": 200
      }
    }
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |
| `Players` | array | Players that hit the ball that frame. |
| `Players[].Name` | string | Display name. |
| `Players[].Shortcut` | int | Spectator shortcut. |
| `Players[].TeamNum` | int | Team index (`0` = Blue, `1` = Orange). |
| `Ball` | object | Ball state at the moment of the hit. |
| `Ball.PreHitSpeed` | float | Ball speed before the hit (Unreal Units/second). |
| `Ball.PostHitSpeed` | float | Ball speed after the hit (Unreal Units/second). |
| `Ball.Location` | vector | World position of the ball at impact. |

---

### ClockUpdatedSeconds

Sent when the in-game clock has changed.

```json
{
  "Event": "ClockUpdatedSeconds",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "TimeSeconds": 180,
    "bOvertime": false
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |
| `TimeSeconds` | int | Seconds remaining in the match. |
| `bOvertime` | bool | True if the game is in overtime. |

---

### CountdownBegin

Sent at the start of each round when the countdown starts.

```json
{
  "Event": "CountdownBegin",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### CrossbarHit

Sent when the ball hits a crossbar.

```json
{
  "Event": "CrossbarHit",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "BallLocation": {
      "X": 120,
      "Y": -2944,
      "Z": 320
    },
    "BallSpeed": 870.3,
    "ImpactForce": 127.5,
    "BallLastTouch": {
      "Player": {
        "Name": "PlayerA",
        "Shortcut": 1,
        "TeamNum": 0
      },
      "Speed": 120
    }
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |
| `BallLocation` | vector | World position of the ball when the impact occurred. |
| `BallSpeed` | float | Ball speed on impact. |
| `ImpactForce` | float | Impact force of the ball relative to the crossbar normal. |
| `BallLastTouch` | object | The last touch of the ball before the crossbar hit. |
| `BallLastTouch.Player` | object | The player who made the last touch. |
| `BallLastTouch.Player.Name` | string | Display name. |
| `BallLastTouch.Player.Shortcut` | int | Spectator shortcut. |
| `BallLastTouch.Player.TeamNum` | int | Team index (`0` = Blue, `1` = Orange). |
| `BallLastTouch.Speed` | float | Speed of the ball resulting from this hit. |

---

### GoalReplayEnd

Sent when a goal replay ends.

```json
{
  "Event": "GoalReplayEnd",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### GoalReplayStart

Sent when a goal replay starts.

```json
{
  "Event": "GoalReplayStart",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### GoalReplayWillEnd

Sent when the ball explodes during a goal replay. Does not fire if the replay is skipped.

```json
{
  "Event": "GoalReplayWillEnd",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### GoalScored

Sent when a goal is scored.

```json
{
  "Event": "GoalScored",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "GoalSpeed": 87.3,
    "GoalTime": 127.5,
    "ImpactLocation": {
      "X": 0,
      "Y": -2944,
      "Z": 320
    },
    "Scorer": {
      "Name": "PlayerA",
      "Shortcut": 1,
      "TeamNum": 0
    },
    "Assister": {
      "Name": "PlayerC",
      "Shortcut": 3,
      "TeamNum": 0
    },
    "BallLastTouch": {
      "Player": {
        "Name": "PlayerA",
        "Shortcut": 1,
        "TeamNum": 0
      },
      "Speed": 125
    }
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |
| `GoalSpeed` | float | Speed of the ball (Unreal Units/second) when it crossed the goal line. |
| `GoalTime` | float | Length of the previous round in seconds. |
| `ImpactLocation` | vector | World position of the ball when the goal was scored. |
| `Scorer` | object | The player who scored the goal. |
| `Scorer.Name` | string | Display name of the scorer. |
| `Scorer.Shortcut` | int | Spectator shortcut. |
| `Scorer.TeamNum` | int | Team index of the scorer. |
| `Assister` | object | **CONDITIONAL** — Same shape as `Scorer`. Present only when an assist was recorded. |
| `Assister.Name` | string | Display name of the assister. |
| `Assister.Shortcut` | int | Spectator shortcut. |
| `Assister.TeamNum` | int | Team index of the assister. |
| `BallLastTouch` | object | The last touch of the ball before the goal. |
| `BallLastTouch.Player` | object | The player who made the last touch. |
| `BallLastTouch.Player.Name` | string | Name of the player who last touched the ball. |
| `BallLastTouch.Player.Shortcut` | int | Spectator shortcut. |
| `BallLastTouch.Player.TeamNum` | int | Team index. |
| `BallLastTouch.Speed` | float | Speed of the ball resulting from this touch. |

---

### MatchCreated

Sent when all teams are created and replicated.

```json
{
  "Event": "MatchCreated",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### MatchInitialized

Sent when the first countdown starts.

```json
{
  "Event": "MatchInitialized",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### MatchDestroyed

Sent when leaving the game.

```json
{
  "Event": "MatchDestroyed",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### MatchEnded

Sent when the match ends and a winner is chosen.

```json
{
  "Event": "MatchEnded",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "WinnerTeamNum": 0
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |
| `WinnerTeamNum` | int | Team index of the winning team. |

---

### MatchPaused

Sent when the game is paused by a match admin.

```json
{
  "Event": "MatchPaused",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### MatchUnpaused

Sent when the game is unpaused by a match admin.

```json
{
  "Event": "MatchUnpaused",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### PodiumStart

Sent when the game enters the podium state after the match ends.

```json
{
  "Event": "PodiumStart",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### ReplayCreated

Sent when a replay is initialized. Applies to replays loaded via the Match History menu, not goal replays.

```json
{
  "Event": "ReplayCreated",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### RoundStarted

Sent when the game enters the active state (after the countdown finishes).

```json
{
  "Event": "RoundStarted",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6"
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |

---

### StatfeedEvent

Sent when a player earns a stat (demolition, save, etc.).

```json
{
  "Event": "StatfeedEvent",
  "Data": {
    "MatchGuid": "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "EventName": "Demolish",
    "Type": "Demolition",
    "MainTarget": {
      "Name": "PlayerA",
      "Shortcut": 1,
      "TeamNum": 0
    },
    "SecondaryTarget": {
      "Name": "PlayerB",
      "Shortcut": 2,
      "TeamNum": 1
    }
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `MatchGuid` | string | Only set for online or LAN matches. |
| `EventName` | string | Asset name of the stat event (e.g. `Demolish`, `Save`). |
| `Type` | string | Localized display label for the stat (e.g. `Demolition`). |
| `MainTarget` | object | Player who earned the stat. |
| `MainTarget.Name` | string | Display name. |
| `MainTarget.Shortcut` | int | Spectator shortcut. |
| `MainTarget.TeamNum` | int | Team index (`0` = Blue, `1` = Orange). |
| `SecondaryTarget` | object | **CONDITIONAL** — Other player involved (e.g. demolished player). Same shape as `MainTarget`. |
| `SecondaryTarget.Name` | string | Display name. |
| `SecondaryTarget.Shortcut` | int | Spectator shortcut. |
| `SecondaryTarget.TeamNum` | int | Team index. |

---

## Event index

| Event | Trigger |
| --- | --- |
| `UpdateState` | Periodic (rate = `PacketSendRate`) |
| `BallHit` | One frame after ball contact |
| `ClockUpdatedSeconds` | In-game clock changed |
| `CountdownBegin` | Round countdown starts |
| `CrossbarHit` | Ball hits crossbar |
| `GoalReplayEnd` | Goal replay ends |
| `GoalReplayStart` | Goal replay starts |
| `GoalReplayWillEnd` | Ball explodes during goal replay (skipped replays omit this) |
| `GoalScored` | Goal scored |
| `MatchCreated` | Teams created and replicated |
| `MatchInitialized` | First countdown starts |
| `MatchDestroyed` | Player leaves the game |
| `MatchEnded` | Match ends with a winner |
| `MatchPaused` | Match admin pauses |
| `MatchUnpaused` | Match admin unpauses |
| `PodiumStart` | Post-match podium state |
| `ReplayCreated` | Match History replay initialized |
| `RoundStarted` | Active play begins (countdown finished) |
| `StatfeedEvent` | Player earns a stat |

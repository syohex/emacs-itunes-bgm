# itunes-bgm.el

Inspired by [hitode909](https://github.com/hitode909)'s [bgm](https://github.com/hitode909/bgm).


## Introduction

BGM by [iTunes search API](https://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html).


## Requirements

- Emacs 24.1 or higher


## Basic Usage

#### `M-x itunes-bgm`

Search keyword and play its result.

#### `M-x itunes-bgm-kill`

Kill player process.


## Customization

#### `itunes-bgm-country`(Default: `"US"`)

[ISO 3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code.

#### `itunes-bgm-player`

Support following players.

- `'mplayer`
- `'avplay`
- `'ffplay`

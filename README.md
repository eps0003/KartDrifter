# Kart Drifter
A 2D top-down racing game made in Ruby!

## Features
- High-octane drifting
- Track editor
- Race against your best replays

## Screenshots
<details>
  <summary>Click to expand!</summary>
  <img src="/Screenshots/main-menu.png" alt="main menu />
  <img src="/Screenshots/controls.png" alt="controls" />
  <img src="/Screenshots/track-select.png" alt="track select" />
  <img src="/Screenshots/countdown.png" alt="race countdown" />
  <img src="/Screenshots/replay.png" alt="replay" />
  <img src="/Screenshots/race-complete.png" alt="race complete" />
  <img src="/Screenshots/editor.png" alt="track editor" />
</details>

## How to play
1. Install [Ruby](https://www.ruby-lang.org/)
2. Install [Gosu](https://www.libgosu.org/) gem - `gem install gosu`
3. Download and extract the repository files
4. Run the game - `ruby ./main.rb`

## Context
This project was made in late 2019 for a High Distinction mark (80%+) in my [Introduction to Programming](https://www.swinburne.edu.au/study/courses/units/Introduction-to-Programming-COS10009/local) university unit.

[Gosu](https://www.libgosu.org/) was taught throughout the semester which is why I used it in this project.

The requirement for this project was to follow the [functional programming](https://en.wikipedia.org/wiki/Functional_programming) paradigm. The only exception was that, for some reason, we were allowed to use classes only to hold data. Methods had to be functions outside of classes.

## Changes since submission
The changes since submitting this project are:
- Moving code out of a single file (since we had to submit the code in one file)
- Fixed error when attempting to save a replay when the `Replays` folder doesn't exist

# GoHangmanClient

TL;DR: Play the hangman game with your Twitch chat. You need to download this client and have access to a running [Backend](https://github.com/Poolitzer/GoHangmanServer).

* Table of contents:
  * [Pictures](#pictures)
  * [Introductionary words](#introductionary-words)
  * [Words of Warning](#words-of-warning)
  * [Features](#features)
  * [Acknowledgments](#acknowledgments)
  * [Contributing, Asking questions, feature suggestions, etc.](#contributing-asking-questions-feature-suggestions-etc)
  * [License](#license)

## Pictures
<p float="left">
  <img src="/showcaseIngame.png" width="500" />
  <img src="/showcase.png" width="500" />
</p>

## Introductionary words
Hello there. 

I have made a video for the type of people who rather watch than read. Feel free to give it a look instead: https://youtu.be/fwi4ON2RfE4.

You want to read? Great. This is a small application you need to run on your streaming PC. It has a first time setup which will guide you through all the settings, but you can change them later if you want to.

You need access to a running [Backend](https://github.com/Poolitzer/GoHangmanServer). You can self host this, even on the same PC you stream with. Or you can [ask me](https://poolitzer.eu/#contact) about a key for my instance.

The download is over at the release tab, download the [latest one](https://github.com/Poolitzer/GoHangmanClient/releases/latest). I currently export for Windows and Linux, if you have a different platform and it is [supported by GoDot](https://docs.godotengine.org/en/stable/about/faq.html#which-platforms-are-supported-by-godot), make an issue and I will include it.

## Words of warning

This is a beta release! I tested everything extensively, but there will probably be bugs I have missed. Be aware that they might happen, especially if people spend money on this.

If you run into a bug, open an issue and give as many details as possible, thank you :)


## Features

- Two game modes
  - Build the hangman
  - Guess words
- Word gussing
  - Set your own words
  - Import existing lists
  - Use random ones from the internet
- Twitch chat integration
  - Guess words, but e.g. only show the hangman and let the current guess status be known with chat commands
- Twitch money integration 
  - Only people who subscribe/cheer get guesses, or they can reset their timeout
  - Optionally, dont apply these limits to roles in chat
- Extensive settings in apps
  - Change every colour (easy chroma key)
  - Set your own command "triggers"
  - Set your guess costs
  - In-app, so easy to navigate
 
 ## Acknowledgments
 
[GoDot](https://godotengine.org/), for being a joy to work with. The [GoDot Community Discord channel](https://discord.com/invite/4JBkykG) for giving me a place to ask annoying questions, especially `ablecounter`, `derkork`, `Faer Derr`, `緑眼のモンスター`, `Firewill`, `KamiGrave`, `fwoovla`, `Weezy`, `akai shuichi` and `NCarter`.

Thanks also go out to [Яico](https://github.com/d-Rickyy-b) for being helpful whenever I got stuck anywhere, and [TheZeldaMuse](https://www.twitch.tv/thezeldamuse) for testing!

Lastly, thanks to [fir](https://www.twitch.tv/fir_) who originally had this idea.
 
## Contributing, Asking questions, feature suggestions, etc.
Yes, please, that is the spirit of open source. Make an issue for anything!
 
## License 
This project is licensed under the GNU General Public License v3.0. You may copy, distribute and modify the software provided that modifications are described and licensed for free under [GPL-3](./license).

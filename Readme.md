PokéBot
=======
An automated computer program that speedruns Pokémon.

Pokémon Red Any%: [1:51:11](https://www.youtube.com/watch?v=M4pOlQ-mIoc) (23 June 2014)

Watch Live
==========
### [http://www.twitch.tv/thepokebot](http://www.twitch.tv/thepokebot)
PokéBot's official streaming channel on Twitch. Consider following there to find out when we're streaming, or follow the [Twitter feed](https://twitter.com/thepokebot) for announcements when we get personal best pace runs going.

Try it out
==========
Running the PokéBot on your own machine is easy. You will need a Windows environment (it runs great in VM's on Mac too). First, clone this repository (or download and unzip it) to your computer. Install the [BizHawk 1.6.1](http://down.emucr.com/v3/10194002) emulator, and procure a ROM file of Pokémon Red (you should personally own the game).

Open the ROM file with BizHawk, and Pokémon Red should start up. Then, under the 'Tools' menu, select 'Lua Console'. Click the open folder button, and navigate to the PokéBot folder you downloaded. Select 'main.lua' and press open. The bot should start running!

Seeds
=====
PokéBot comes with a built-in run recording feature that takes advantage of random number seeding to reproduce runs in their entirety. Any time the bot resets or beats the game, it will log a number to the Lua console that is the seed for the run. If you set 'CUSTOM_SEED' in main.lua to that number, the bot will reproduce your run, allowing you to share your times with others. Note that making any other modifications will prevent this from working. So if you want to make changes to the bot and share your time, be sure to fork the repo and push your changes.

Credits
=======
### Developers
Kyle Coburn: Original concept, Red routing

Michael Jondahl: Combat algorithm, Java bridge for connecting the bot to Twitch chat, Livesplit, Twitter, etc

### Special thanks
To Livesplit for providing custom component for integrating in-game time splits.

To the Pokémon speedrunning community members who inspired the idea, and shared ways to improve the bot.
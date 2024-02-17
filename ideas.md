# Mechanics

- Standard movement
- Jump / Dash
	- Dash and jump use same charges
		- This limits movement to either one jump, or a dash on the ground.
		- Charges reset on landing, with a minimum cooldown (likely half a second, just enough to slow down repeat dashing
	- Starting state has no charges
	- torso has one charge, only usable on ground
	- Legs gives two charges, can be used in air
		- Allows double jump, combining dash and jump, or two dashes off a ledge
	- Possible third charge as secret upgrade?
- Grapple
	- Shoots in a straight line with a maximum range
	- four or eight directional
	- Primarily used as a substitute for a ranged weapon, for puzzles before platforming
	- Ideas:
		- Grapple does not auto pull, character stops falling / freezes in place, can press a second button to pull itself towards the grapple point, or jump
		- Different grapple points have different effects, such as a charged point resetting your dash charges, a hackable point moving an object in the world
- "Ikaruga" shield
	- Red/blue polarity
	- starts with a single polarity, and it turns off automatically when using some other ability (like the dash) to give the player a chance to familiarize with the power-up
	- eventually, the player gains the other polarity and the shield no longer turns off
- Damage
	- No death or health
	- Being hit by the wrong polarity stuns you, forcing you to fall.
		- No input would work for some time
		- either a second or so to allow you to recover, or until you hit the ground?
- Screen clear
	- Single use bomb that wipes all projectiles from the screen
	- Optional upgrades increases bomb count
	- Bombs only recharge at save rooms

# Level Construction

- Grid based, possibly using godot's TileMap
- Moving Platforms
	- Moving actor type, attached to spline
	- Linear only, or do we allow cycles?

# Story Outline

- Crash land on an inhabited planet
- Start as a small orb-like robot head
	- Slow movement
	- climb/crawl through vents
- Gain upper torso (arms and jet-pack)
	- faster movement
	- jump from jet-pack (while on ground)
	- dash from jet-pack (while on ground)
- Gain legs
	- full-speed movement
	- ground & air dash
	- double jump from legs and jet-pack
- Escape the planet

# Tasks

- Test level
- Camera movement
- Character movement
- Enemy AI / movement
- Environment behaviors
- Collision layers
- Room transitions
- Enemy types
- Main Menu UI
- Game Menu UI
- HUD UI(?)
- Art
	- character head
	- character torso / arms
	- character legs
	- defense turret side
	- defense turret diagonal
	- defense turret up / down
	- mining laser (blocks? turrets?)
	- defense lasers
	- internal tiles
		- ceiling
		- walls
		- doors
		- decoration
	- scaffold tiles
	- external tiles(?)
		- walls
		- doors
- Sound Effects
	- lasers
	- turret shots
	- character walk
	- character jump
	- character dash
	- character grapple
	- menu movement
	- menu accept
	- menu reject

require_relative "output.rb"
require_relative "input.rb"
require_relative "mapping.rb"
require_relative "creatures.rb"
require_relative "items.rb"

#get player name
print "What's your name? > "
name = gets.chomp

pclass = 0
until pclass == 'a' || pclass == 'b' || pclass == 'c' || pclass == 'd' || pclass == 'g' || pclass == 's'
	puts "Classes: a - rogue, b - warrior, c - barbarian, d - hoplite"
	puts "Monsters: g - goblin, s - scoundrel"
	print "> "
	pclass = gets.chomp
end

#initialize console
Output.setup_console

#constants
MAIN_SIZE = [60, 18]
STATUS_SIZE = [MAIN_SIZE[0], 6]
PLAYER_SIZE = [20, MAIN_SIZE[1] + STATUS_SIZE[1]]

#initialize views
$main_view = Output::View.new(0, 0, MAIN_SIZE[0], MAIN_SIZE[1])
$status_view = Output::StatusView.new(0, MAIN_SIZE[1], STATUS_SIZE[0], STATUS_SIZE[1])
$player_view = Output::View.new(MAIN_SIZE[0], 0, PLAYER_SIZE[0], PLAYER_SIZE[1])

#generate map
$map = Mapping::Map.new(0, 0, 100, 100)
coords = $map.populate

#generate player
if pclass == 'b'
	$player = Creatures::Player.new(coords[0], coords[1], name)
elsif pclass == 'a'
	$player = Creatures::Rogue.new(coords[0], coords[1], name)
elsif pclass == 'c'
	$player = Creatures::Barbarian.new(coords[0], coords[1], name)
elsif pclass == 'd'
	$player = Creatures::Hoplite.new(coords[0], coords[1], name)
elsif pclass == 'g'
	$player = Creatures::Goblin.new(coords[0], coords[1], name)
	$player.player = true
elsif pclass == 's'
	$player = Creatures::Scoundrel.new(coords[0], coords[1], name)
	$player.player = true
end

#spawn items
num = rand(5..10)
$items = Items.items_generator(num, $map)

#spawn monsters
$monsters = []
number = rand(7..21)
i = 0
until i >= number
	tile = false
	until tile
		ntile = $map.tiles.sample
		tile = ntile unless ntile.blocked || Mapping.exists($monsters, ntile.x, ntile.y) || ($player.x == ntile.x && $player.y == ntile.y)
	end
	if rand(1..10) > 8
		$monsters.push(Creatures::GoblinWarlord.new(tile.x, tile.y))
	elsif rand(1..10) > 4
		$monsters.push(Creatures::Goblin.new(tile.x, tile.y))
	elsif rand(1..10) > 3
		$monsters.push(Creatures::Scoundrel.new(tile.x, tile.y))
	else
		$monsters.push(Creatures::Bomber.new(tile.x, tile.y))
	end
	i += 1
end

tile = false
until tile
	ntile = $map.tiles.sample
	tile = ntile unless ntile.blocked || Mapping.exists($monsters, ntile.x, ntile.y) || ($player.x == ntile.x && $player.y == ntile.y)
end

$monsters.push(Creatures::Nazgul.new(tile.x, tile.y))

#initial draw (so screen isn't empty before input)
Mapping.recalc_fov($player)
$map.draw($main_view)
$player.draw($main_view)
$items.each {|item| item.draw($main_view)}
$monsters.each {|monster| monster.draw($main_view)}

#status
$status_view.add_to_buffer("Welcome to Welmish Woundikins!")
$status_view.add_to_buffer("If you can't see the player menu, exit the game and resize screen.")
$status_view.add_to_buffer("A nazgul is terrorizing your homeland.")
$status_view.draw_buffer

#main loop
while 1
	$player_view.clear
	$player.state($player_view)
	$player_view.refresh
	Mapping.recalc_fov($player)
	
	#$main_view.window.box('*', '*') #for window border, it flashes annoying sometimes though
	
	key = Input.get_key($main_view.window)
	
	#check if the player moved
	x = $player.x
	y = $player.y
	
	$player.check_if_dead
	$player.act(key) #give player control
	
	$monsters.each {|monster|
		if monster.hp <= 0
			monster.death
			$player.kills += 1
			Mapping.recalc_fov($player)
		end}

	$main_view.clear
	$map.draw($main_view)
	$items.each {|item| item.draw($main_view)}
	$player.draw($main_view)
	
	$monsters.each {|monster|
		monster.draw($main_view)
		monster.act
		monster.regen}
	
	$main_view.refresh
	
	$player.regen
	break if key == 'Q'
end

Output.close_console
exit

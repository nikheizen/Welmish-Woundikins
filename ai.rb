#File with mixins defining monster actions
require_relative "mapping.rb"
require_relative "input.rb"

$alphabet = []
('a'..'z').each {|char| $alphabet.push(char)}

module PlayerAI #player controlled
	def self.act(key, player)
		#default movement values
		dirx = 0
		diry = 0
			
		case key 
			
		#movement (and combat)
		when 'k' #up
			diry = -1
		when 'j' #down
			diry = 1
		when 'h' #left
			dirx = -1
		when 'l' #right
			dirx = 1
		when 'y' , 'z' #up-left
			dirx = -1
			diry = -1
		when 'u' #up-right
			dirx = 1
			diry = -1
		when 'b' #down-left
			dirx = -1
			diry = 1
		when 'n' #down-right
			dirx = 1
			diry = 1
		when '.' #wait
			dirx = 0
			diry = 0
			
		#item manipulationg
		when ',' #pick item up
			item = Mapping.exists($items, player.x, player.y)
			
			if item
				item.pick_up(player)
			else
				$status_view.add_to_buffer("You see no items here.")
				$status_view.draw_buffer
			end
		when 'd' #drop item
			$status_view.add_to_buffer("Which item?")
			$status_view.draw_buffer
			
			index = Input.get_key($main_view.window)
				
			item = false
			item = player.inventory[index.to_i] if index.to_i < player.inventory.count
			if item
				item.drop(player) 
			else
				$status_view.add_to_buffer("You don't have that item.")
				$status_view.draw_buffer
			end
		when 'i' #display inventory
			$status_view.add_to_buffer("Inventory:")
			i = 0
			player.inventory.each {|item| 
				$status_view.add_to_buffer("#{$alphabet[i]}: #{item.name}")
				i += 1}

			$status_view.draw_buffer
		when 'e' #display equipment
			$status_view.add_to_buffer("Equipment:")
			i = 0
			player.equipment.each {|item|
				$status_view.add_to_buffer("#{$alphabet[i]}: #{item.name}")
				i += 1}
			$status_view.draw_buffer
		when 'w' #wear or wield
			$status_view.add_to_buffer("Which item?")
			$status_view.draw_buffer
				
			char = Input.get_key($main_view.window)
			index = $alphabet.index(char)
				
			item = false
			item = player.inventory[index] if index || index < player.inventory.count
			
			if item && item.is_a?(Items::Wearable)
				slots_taken = 0
				player.equipment.each {|nitem| slots_taken += 1 if nitem.slot == item.slot}
				
				if slots_taken < player.slots[item.slot]
					item.wear(player) 
				else
					$status_view.add_to_buffer("You don't have enough #{item.slot}s.")
					$status_view.draw_buffer
				end
			else
				$status_view.add_to_buffer("You don't have that item.")
				$status_view.draw_buffer
			end
		when 't' #take off
			$status_view.add_to_buffer("Which item?")
			$status_view.draw_buffer
				
			char = Input.get_key($main_view.window)
			index = $alphabet.index(char)
				
			item = false
			item = player.equipment[index] if index < player.equipment.count
			
			if item 
				item.take_off(player)
			else
				$status_view.add_to_buffer("You don't have that item.")
				$status_view.draw_buffer
			end
			
		when 'r' #read
			$status_view.add_to_buffer("Which item?")
			$status_view.draw_buffer
				
			char = Input.get_key($main_view.window)
			index = $alphabet.index(char)
				
			item = false
			item = player.inventory[index] if index < player.inventory.count
			
			if item && item.is_a?(Items::Scroll)
				item.read(player) 
			else
				$status_view.add_to_buffer("You don't have that item.")
				$status_view.draw_buffer
			end
		when 'q' #quaff
			$status_view.add_to_buffer("Which item?")
			$status_view.draw_buffer
				
			char = Input.get_key($main_view.window)
			index = $alphabet.index(char)
				
			item = false
			item = player.inventory[index] if index < player.inventory.count
			
			if item && item.is_a?(Items::Potion)
				item.quaff(player)
			else
				$status_view.add_to_buffer("You don't have that item.")
				$status_view.draw_buffer
			end
				
		#misc
		when '?'
			$status_view.add_to_buffer("Nethack keys for movement and attacking,")
			$status_view.add_to_buffer("',' to pick up item, 'd' to drop it")
			$status_view.add_to_buffer("'w' - wear/wield, 't' - take off,  'q' - quaff, 'r' - read")
			$status_view.add_to_buffer("'?' for help, 'Q' to quit, '.' to wait")
			$status_view.add_to_buffer("'i' - display inventory, 'e' - display equipment.")
			$status_view.add_to_buffer("Good luck.")
			$status_view.draw_buffer
				
			key = Input.get_key($main_view.window)
			player.act(key)
		when 'Q' #exit
			Output.close_console
			exit
		else
			$status_view.add_to_buffer("I don't know that key,")
			$status_view.add_to_buffer("Click '?' for help")
			$status_view.draw_buffer
				
			key = Input.get_key($main_view.window)
			player.act(key)
		end
			
		#recalc damage
		if player.hp <= player.max_hp / 6 && player.is_a?(Creatures::Barbarian)
			player.dmg[0] += 1
		end
			
		monster = Mapping.exists($monsters, player.x + dirx, player.y + diry) 
		if monster
			Combat.attack(player, monster)
		else
			unless Mapping.exists($map.tiles, player.x + dirx, player.y + diry).blocked
				player.move(dirx, diry)
			end
		end
			
		true
	end
end

module RandomAI #move randomly around
	def self.act(player)
		dirs = [-1, 0, +1]
		xdir = dirs.sample
		ydir = dirs.sample
		player.move(xdir, ydir) unless (not Mapping.exists($map.tiles, player.x + xdir, player.y + ydir)) || Mapping.exists($map.tiles, player.x + xdir, player.y + ydir).blocked
	end
end

module SeekerAI #move towards player
	def self.act(player)
		xdir = (($player.x - player.x) / ($player.x - player.x).abs) unless $player.x == player.x
		xdir = 0 if $player.x == player.x
				
		ydir = (($player.y - player.y) / ($player.y - player.y).abs) unless $player.y == player.y
		ydir = 0 if $player.y == player.y
				
		player.move(xdir, ydir) unless (not Mapping.exists($map.tiles, player.x + xdir, player.y + ydir)) || Mapping.exists($monsters, player.x + xdir, player.y + ydir) || (player.x + xdir == $player.x && player.y + ydir == $player.y) || Mapping.exists($map.tiles, player.x + xdir, player.y + ydir).blocked
	end
end

module RunnerAI #move away from player
	def self.act(player)
		xdir = -(($player.x - player.x) / ($player.x - player.x).abs) unless $player.x == player.x
		xdir = 0 if $player.x == player.x
				
		ydir = -(($player.y - player.y) / ($player.y - player.y).abs) unless $player.y == player.y
		ydir = 0 if $player.y == player.y
				
		player.move(xdir, ydir) unless Mapping.exists($map.tiles, player.x + xdir, player.y + ydir).blocked || Mapping.exists($monsters, player.x + xdir, player.y + ydir) || (player.x + xdir == $player.x && player.y + ydir == $player.y)
	end
end

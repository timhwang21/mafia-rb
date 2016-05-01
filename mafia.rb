require_relative 'player'

class Mafia
  attr_reader :players, :round
  def initialize(players = nil)
    @players = players ? players : get_players
    @round = 1
  end

  def run
    assign_roles
    show_roles

    until over?
      handle_night
      handle_day
      @round += 1
    end
    system('clear')
    handle_win
  end

  def self.play
    Mafia.new.run
  end

  def self.play_joobie
    players = {
      0 => Player.new("Tim"),
      1 => Player.new("Tom"),
      2 => Player.new("Josh"),
      3 => Player.new("Rick"),
      4 => Player.new("Yian"),
      5 => Player.new("Imaginary Friend")
    }
    
    Mafia.new(players).run
  end

  private

  def get_players
    players = {}
    system('clear')
    puts "Enter your name: "
    player_name = gets.chomp

    until player_name == ""
      players[players.length] = Player.new(player_name)
      system('clear')
      puts "Hi, #{player_name}. You've been added to the game. Please press enter and pass the computer to your left."
      gets

      system('clear')
      puts "You have enough players! Press enter to start, or add more players."if players.length >= 5
      puts "Enter your name: "
      player_name = gets.chomp
    end

    if players.length < 5
      raise "Not enough players!"
    end

    players
  end

  def assign_roles
    deck = []

    case @players.length
    when 5
      deck << :mafia
      4.times { deck << :citizen }
    when 6
      deck << :inspector
      deck << :mafia
      4.times { deck << :citizen }
    when 7
      deck << :inspector
      2.times { deck << :mafia }
      4.times { deck << :citizen }
    when 8
      deck << :inspector
      2.times { deck << :mafia }
      5.times { deck << :citizen }
    end

    deck.shuffle!
    @players.each { |id, player| player.role = deck.pop }
  end

  def show_roles
    round = @players.keys

    until round.empty?
      system('clear')
      current_player = get_current_player(round)

      system('clear')
      puts "Current player: #{current_player.name}\nPress enter to receive your role."
      gets

      system('clear')
      puts "Your role is: #{current_player.role}"
      puts "Pass the computer to your left."
      gets
    end

    system('clear')
    puts "Roles have been assigned. The game is starting!"
    gets
  end

  def handle_night
    round = living_players.keys
    until round.empty? 
      system('clear')
      puts "ROUND #{@round}: NIGHT TIME"
      current_player = get_current_player(round)

      system('clear')
      case current_player.role
      when :mafia
        puts living_players_to_s
        puts "Hi #{current_player.name}. You are the mafia. Enter the ID of someone to kill."
        target = @players[gets.chomp.to_i]
        system('clear')
        puts "#{target.name} will die. Press any key and enter."
        gets
      when :inspector
        puts living_players_to_s
        puts "Hi #{current_player.name}. You are the inspector. Enter the ID of someone to inspect."
        inspected = @players[gets.chomp.to_i]
        system('clear')
        puts inspected.role == :mafia ? "#{inspected.name} is a MAFIA!!!" : "#{inspected.name} is NOT a mafia."
        puts "Press any key and enter."
        gets
      else
        puts "Hi #{current_player.name}. You are a civilian. Sleeping..."
        sleep(rand(1..3))
        puts "Press a random key, then hit enter."
        gets
        puts "Press enter to continue."
        gets
      end

      system('clear')
      puts "Pass the computer to your left."
      gets
    end

    system('clear')
    puts "The night is over!"
    gets

    puts "#{target.name} has been killed by the mafia!"
    target.kill
    gets

    puts "Press enter to continue."
    gets
  end

  def handle_day
    round = living_players.keys
    votes = Hash[round.map {|id| [id, 0]}]
    until round.empty?
      system('clear')
      puts "ROUND #{@round}: DAY TIME - VOTING"
      current_player = get_current_player(round)

      system('clear')
      puts living_players_to_s
      puts "Hi #{current_player.name}. Who do you think is the mafia?"
      votes[gets.chomp.to_i] += 1

      system('clear')
      puts "Pass the computer to your left."
      gets
    end

    system('clear')
    puts "The votes are in!"
    gets

    target_id, vote_count = votes.max_by { |id, count| count }
    if votes.select { |id, count| count == vote_count}.length > 1
      puts "There was a tie! Press enter to restart the voting process."
      gets
      handle_day
    else
      target = @players[target_id]
      puts "#{target.name} had the most votes, with #{vote_count} votes! #{target.name} has been lynched!"
      target.kill
      gets

      puts "Press enter to continue."
      gets
    end
  end

  def over?
    mafia_win? || civilians_win?
  end

  def handle_win
    puts civilians_win? ? "Civilians win!" : "Mafia wins!"
    puts "The mafia was: #{whois(:mafia)}"
  end

  def get_current_player(round)
    puts living_players_to_s(round)
    puts "Enter your id:"
    id = gets.chomp.to_i
    round.delete(id)
    @players[id]
  end

  def whois(role)
    @players.select { |id, player| player.role == role }.map { |id, player| player.name }.join(", ")
  end

  def living_players
    @players.select { |id, player| player.alive }
  end

  def living_players_to_s(round = nil)
    if round.nil?
      living_players.map { |id, player| "#{id}: #{player.to_s}" }.join("\n")
    else
      living_players.select { |id, player| round.include? id }.map { |id, player| "#{id}: #{player.to_s}" }.join("\n")
    end
  end

  def num_civilians_alive
    living_players.count { |id, player| player.role != :mafia }
  end

  def num_mafia_alive
    living_players.count { |id, player| player.role == :mafia }
  end

  def mafia_win?
    num_mafia_alive >= num_civilians_alive
  end

  def civilians_win?
    num_mafia_alive == 0
  end
end
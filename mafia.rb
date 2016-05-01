require_relative 'player'

class Mafia
  attr_reader :players, :round
  attr_accessor :current_player

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
    players = {}
    friends = %w(Tim Tom Josh Rick Yian ImaginaryFriend)
    friends.each_with_index { |friend, idx| players[idx] = Player.new(friend)}
    
    Mafia.new(players).run
  end

  private

  def get_players
    players = {}
    system('clear')
    print "Enter your name:\n=> "
    player_name = gets.chomp

    until player_name == ""
      players[players.length] = Player.new(player_name)
      system('clear')
      puts "Hi, #{player_name}. You've been added to the game. Please press ENTER and pass the computer to your left."
      gets

      system('clear')
      puts "You have enough players! Press ENTER to start, or add more players."if players.length >= 5
      print "Enter your name:\n=> "
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
    when 9
      deck << :inspector
      3.times { deck << :mafia }
      5.times { deck << :citizen }
    when 10
      deck << :inspector
      3.times { deck << :mafia }
      6.times { deck << :citizen }
    when 11
      deck << :inspector
      3.times { deck << :mafia }
      7.times { deck << :citizen }
    end

    deck.shuffle!
    @players.each { |id, player| player.role = deck.pop }
  end

  def show_roles
    round = @players.keys

    until round.empty?
      system('clear')
      set_current_player(round)

      system('clear')
      puts "Current player: #{current_player.name}\nPress ENTER to receive your role."
      gets

      system('clear')
      puts "Your role is: #{@current_player.role.to_s.upcase}\nPass the computer to your left."
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
      puts "ROUND #{@round}: NIGHT TIME\n"
      set_current_player(round)

      system('clear')
      case @current_player.role
      when :mafia
        target ||= nil
        target = handle_mafia(target)
      when :inspector
        handle_inspector
      else
        handle_citizen
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

    puts "Press ENTER to continue."
    gets
  end

  def handle_day
    round = living_players.keys
    votes = Hash[round.map {|id| [id, 0]}]
    until round.empty?
      system('clear')
      puts "ROUND #{@round}: DAY TIME - VOTING\n"
      set_current_player(round)

      system('clear')
      puts (@current_player.is_mafia? ? living_players_mafiavision_to_s : living_players_to_s)
      print "__________________\nHi #{@current_player.name}. Who do you think is the mafia?\n=> "
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
      puts "There was a tie! Press ENTER to restart the voting process."
      gets
      handle_day
    else
      target = @players[target_id]
      puts "#{target.name} had the most votes, with #{vote_count} votes! #{target.name} has been lynched!"
      target.kill
      gets

      puts "Press ENTER to continue."
      gets
    end
  end

  def over?
    mafia_win? || civilians_win?
  end

  def handle_mafia(target)
    puts "CIVILIANS\n#{living_civilians_to_s}\n\nMAFIA\n#{living_mafia_to_s}\n__________________"
    puts "Hi, #{@current_player.name}. You are the MAFIA.\nEnter the ID of someone to kill."

    puts "A previous MAFIA has selected #{target.name}. You may change the target if you want." if target

    print "=> "
    target = @players[gets.chomp.to_i]

    system('clear')
    puts "#{target.name} has been marked for death.\nPress any key and ENTER."
    gets

    target
  end

  def handle_inspector
    puts "LIVING PLAYERS\n#{living_players_to_s}\n__________________"
    print "Hi, #{@current_player.name}. You are the INSPECTOR.\nEnter the ID of someone to inspect.\n=> "
    inspected = @players[gets.chomp.to_i]

    system('clear')
    puts inspected.is_mafia? ? "#{inspected.name} is a MAFIA!!!" : "#{inspected.name} is NOT a mafia."
    puts "Press any key and ENTER."
    gets
  end

  def handle_citizen
    puts "Hi #{@current_player.name}. You are a civilian. Sleeping..."
    sleep(rand(2..3))
    puts "Press a random key, then hit ENTER."
    gets
    puts "Press ENTER to continue."
    gets
  end

  def handle_win
    puts civilians_win? ? "Civilians win!" : "Mafia wins!"
    puts "The mafia was: #{whois(:mafia)}"
  end

  def set_current_player(round)
    puts living_players_to_s(round)
    print "__________________\nEnter your id:\n=> "
    id = gets.chomp.to_i
    round.delete(id)
    @current_player = @players[id]
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

  def living_players_mafiavision_to_s
    living_players.map { |id, player| "#{id}: #{player.to_s} #{("MAFIA") if player.is_mafia?}" }.join("\n")
  end

  def living_civilians
    living_players.select { |id, player| !player.is_mafia? }
  end

  def living_civilians_to_s
    living_civilians.map { |id, player| "#{id}: #{player.to_s}" }.join("\n")
  end

  def living_mafia
    living_players.select { |id, player| player.is_mafia? }
  end

  def living_mafia_to_s
    living_mafia.map { |id, player| "#{player.to_s}" }.join("\n")
  end

  def num_civilians_alive
    living_civilians.length
  end

  def num_mafia_alive
    living_mafia.length
  end

  def mafia_win?
    num_mafia_alive >= num_civilians_alive
  end

  def civilians_win?
    num_mafia_alive == 0
  end
end

if __FILE__==$0
  $:.unshift File.expand_path("../../", __FILE__)  
  Mafia.play
end
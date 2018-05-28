
# The Tic_Tac_Toe game squares
class Square

  def initialize(number)
    @position = number
    @selected = false
    @owner = nil
  end

end

# A player in the game
class Player
  attr_reader :name
  attr_accessor :role

  def initialize(name)
    @name = name
    @role = ""
  end

  def guess_code
    guess = ["_", "_", "_", "_"]
    options = (1..6).to_a
    selector = ["first", "second", "third", "fourth"]
    count = 0
    puts "========================================="
    4.times do
      begin
        puts "#{@name}, please select a number for the #{selector[count]} position (1 through 6):"
        choice = gets.chomp.strip.to_i
        unless options.include?(choice)
          raise ArgumentError.new("Selection was not of the correct format.")
        end
      rescue ArgumentError=>e
        puts "Error: #{e.message}"
        retry
      end
      guess[count] = choice
      puts "#{@name} has chosen #{choice.to_s} for the #{selector[count]} position:"
      p guess
      count += 1
    end
    puts "========================================="
    return guess
  end

  def create_code1
    code = []
    4.times do
      code.push(rand(5)+1)
    end
    puts "created code:"
    p code
    puts "end of create code"
    puts ""
    return code
  end

  def create_code2
    code = ["_", "_", "_", "_"]
    options = (1..6).to_a
    selector = ["first", "second", "third", "fourth"]
    count = 0
    puts "=-----=------=-----=-----=----=------=----=----=-----=----="
    puts "creating code:"
    4.times do
      begin
        puts "#{@name}, please select a number for the #{selector[count]} code number (1 through 6):"
        choice = gets.chomp.strip.to_i
        unless options.include?(choice)
          raise ArgumentError.new("Selection was not of the correct format.")
        end
      rescue ArgumentError=>e
        puts "Error: #{e.message}"
        retry
      end
      code[count] = choice
      # puts "#{@name} has chosen #{choice.to_s} for the #{selector[count]} position:"
      p code
      count += 1
    end
    puts "=-----=------=-----=-----=----=------=----=----=-----=----="
    return code
  end

end

# Player operated by a human user
class User < Player

end

# A Player automated by the computer
class Computer < Player

end

# The main game mechanisim
class Mastermind

  def initialize(player_name)
    @player = User.new(player_name)
    @computer = Computer.new("Computer")
    @game_won = false
    @code = []
    @guesses_made = []
    @guess_analytics = {}
  end



  # Initiates the game
  def play_game
    # assume roles
    # maker = set_maker
    maker = @computer
    breaker = (maker == @player) ? @computer : @player
    @code = maker.create_code2
    round = 1
    until (@game_won == true || round > 4)
      puts "Round #{round}"
      current_guess = breaker.guess_code
      @guesses_made.push(current_guess)
      if current_guess == @code
        @game_won = true
      else
        @guess_analytics[current_guess] = analyze_guess
        display_guesses
      end
      round += 1
    end
    show_winner
  end

  def analyze_guess
    puts "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
    puts "inside analyze guess"
    # Record match type: B = position and value, W = value only, N = none
    # position_check = Hash[ (0..3).to_a.collect { |item| [item, "N"] } ]
    # analysis = {}
    analysis = Hash[ (0..3).to_a.collect { |item| [item, "N"] } ]
    code_matches = []
    puts "Creating code_matches:"
    puts ""
    # check each guess position against all code values
    @guesses_made.last.each_with_index do |num_guess, index_guess|
      puts "Matching against: "
      puts "num_guess: #{num_guess} index_guess: #{index_guess} "
      @code.each_with_index do |num_code, index_code|
        puts "num_code: #{num_code} index_code: #{index_code}"
        if (index_guess == index_code && num_guess == num_code)
          code_matches.push([index_guess, index_code, "B"])
          puts "matched B to position: " + index_guess.to_s
        elsif (num_guess == num_code)
          code_matches.push([index_guess, index_code, "W"])
          puts "matched W to position: " + index_guess.to_s
        end
      end
    end
    puts ""
    puts "code_matches:"
    p code_matches
    puts ""

    matches_b = []
    matches_w = []
    # for each guess position: add matches to analysis: dont overwrite with W
    code_matches.each do |match|
      position_guess = match[0]
      position_code = match[1]
      match_type = match[2]
      # skip if "B" match already found at this guess or code position
      unless (match_nested_array_at_subposition?(matches_b, position_guess, 0) ||
              match_nested_array_at_subposition?(matches_b, position_code, 1))
        puts ""
        puts "passed match_nested on match:"
        p match
        case match_type
        when "W"
            matches_w.push(match)
            puts "W added"
        when "B"
          matches_b.push(match)
          puts "B added"
          # if "B" match, remove any saved "W" at this guess or code position
          matches_w.each do |w_match|
            puts "checking old Ws"
            puts "position_guess = " + position_guess.to_s
            puts "position_code = " + position_code.to_s
            if (w_match[0] == position_guess || w_match[1] == position_code)
              matches_w.delete(w_match)
              puts "Deleted W:"
              p w_match
            end
          end
        end
      end
    end
    puts "B matches"
    p matches_b
    puts ""
    puts "W matches"
    p matches_w

    puts ""
    puts "modifying analysis:"
    puts ""

    # add "W" matches to analysis
    # Can only have one "W" for any particular guess position
    w_guess_positions_assigned = []
    w_code_positions_assigned = []
    matches_w.each do |match|
      unless (w_guess_positions_assigned.include?(match[0]) ||
              w_code_positions_assigned.include?(match[1]))
        analysis[match[0]] = match[2]
        w_guess_positions_assigned.push(match[0])
        w_code_positions_assigned.push(match[1])
      end
    end
    #  add "B" matches to analysis
    matches_b.each { |match| analysis[match[0]] = match[2] }
    puts ""
    puts "Analysis made:"
    p analysis
    puts "end analyze_guess"
    puts ""
    puts "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
    return analysis
  end

  # checks to see if there is an item matches any nested array at a specific
  # position. eg: "3" matches in subposition 1 in array [ [1,4], [2,3] ], in
  # the second element (position 1).
  # note: assumes 'array' has size of at least 'subposition + 1'
  #       (no exception handling yet)
  # Returns true upon the first occurrence of a match
  def match_nested_array_at_subposition?(array, item, subposition)
    found_match = false
    array.each do |nested_array|
      if nested_array[subposition] == item
        found_match = true
        break
      end
    end
    return found_match
  end

  #
  # def analyze_guess
  #   puts "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
  #   puts "inside analyze guess"
  #   # Record match type: B = position and value, W = value only, N = none
  #   # position_check = Hash[ (0..3).to_a.collect { |item| [item, "N"] } ]
  #   # analysis = {}
  #   analysis = Hash[ (0..3).to_a.collect { |item| [item, "N"] } ]
  #   code_matches = {}
  #   puts "Creating code_matches:"
  #   puts ""
  #   # check each guess position against all code values
  #   @guesses_made.last.each_with_index do |num_guess, index_guess|
  #     puts "Matching against: "
  #     puts "num_guess: #{num_guess} index_guess: #{index_guess} "
  #     @code.each_with_index do |num_code, index_code|
  #       puts "num_code: #{num_code} index_code: #{index_code}"
  #       if (index_guess == index_code && num_guess == num_code)
  #         code_matches[index_guess] = "B"
  #         puts "matched B to position: " + index_guess.to_s
  #       elsif (!code_matches.has_key?(index_guess) && num_guess == num_code)
  #         code_matches[index_guess] = "W"
  #         puts "matched W to position: " + index_guess.to_s
  #       end
  #     end
  #     puts ""
  #     puts "modifying analysis:"
  #     puts ""
  #     puts "code_matches:"
  #     p code_matches
  #     puts ""
  #     # for each guess position: add matches to analysis: dont overwrite with W
  #     code_matches.each do |position, match_type|
  #       puts "Code_matches: checking position: " + position.to_s + " (type: " + match_type + ")"
  #       if analysis[position] == "N"
  #         analysis[position] = match_type
  #         puts "added to analysis(N): " + match_type + " at position: " + position.to_s
  #       elsif analysis[position] == "W" && match_type == "B"
  #         analysis[position] = match_type
  #         puts "added to analysis(W): " + match_type + " at position: " + position.to_s
  #       end
  #     end
  #     code_matches = {}
  #   end
  #   puts "Analysis made:"
  #   p analysis
  #   puts "end analyze_guess"
  #   puts ""
  #   puts "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
  #   return analysis
  # end

  def display_guesses
    puts "---------------------------------"
    puts "Code is:"
    p @code
    puts "Guesses thus far:"
    display_array = []
    @guesses_made.each do |guess|
      display_array = [guess, "Matches:", @guess_analytics[guess]]
      puts "guess " + @guesses_made.index(guess).to_s
      p display_array
    end
    puts "end of guesses list"
    puts "---------------------------------"
  end

  # Sets roles of the player and computer as "maker" or "breaker"
  # Returns whichever character is the "maker": player or computer
  def set_maker
    begin
      puts "#{@player.name}, would you like to make (1) or break (2) the code?"
      puts "Please select either '1' or '2':"
      choice = gets.chomp.strip.to_i
      unless [1, 2].include?(choice)
        raise ArgumentError.new("Selection was not of the correct format.")
      end
    rescue ArgumentError=>e
      puts "Error: #{e.message}"
      retry
    end
    @player.role = (choice == 1) ? "maker" : "breaker"
    @computer.role = (@player.role == "maker") ? "breaker" : "maker"
    puts "#{@player.name} has chosen to be the code-#{@player.role}."
    maker = (@player.role == "maker") ? @player : @computer
    return maker
  end

  # Displays the current game board
  def update_game_display

  end

  # Returns true if there is a winner, and updates the winning player object
  def check_winner_exists

  end

  # Displays the winner
  def show_winner
    if @game_won == true
      puts "#{@player.name} Wins!!"
    else
      puts "12 rounds have been played, #{@computer.name} Wins!!"
    end
  end

end

# Play single-player game, one user against the computer
game = Mastermind.new("Jason")
game.play_game



# A player in the game
class Player
  attr_reader :name
  attr_accessor :role, :winner, :guesses_made, :guess_analytics

  def initialize(name)
    @name = name
    @role = ""
    @winner = false
    @guesses_made = []
    @guess_analytics = {}
  end

end

# Player operated by a human user
class User < Player

  def create_code
    begin
      puts ""
      puts "#{@name}, please enter the secret code:"
      puts "(a four digit code, using the numbers 1-6, and no spaces. eg: 1234)"
      choice = gets.chomp.strip
      unless /^[1-6]{4}$/ =~ choice
        raise ArgumentError.new("Selection was not of the correct format.")
      end
    rescue ArgumentError=>e
      puts "Error: #{e.message}"
      retry
    end
    code = choice.split("").map { |letter| letter.to_i }
    puts ""
    puts "#{@name} has entered the secret code:"
    p code
    puts ""
    puts "=================================================="
    return code
  end

  def guess_code
    begin
      puts ""
      puts "#{@name}, please enter your guess:"
      puts "(a four digit code, using the numbers 1-6, and no spaces. eg: 1234)"
      choice = gets.chomp.strip
      unless /^[1-6]{4}$/ =~ choice
        raise ArgumentError.new("Selection was not of the correct format.")
      end
    rescue ArgumentError=>e
      puts "Error: #{e.message}"
      retry
    end
    guess = choice.split("").map { |letter| letter.to_i }
    puts ""
    puts "#{@name} has guessed:"
    p guess
    return guess
  end

end

# A Player automated by the computer
class Computer < Player

  def create_code
    code = []
    4.times { code.push(rand(5)+1) }
    puts ""
    puts "#{@name} has entered the secret code:"
    puts ""
    puts "=================================================="
    return code
  end

  def guess_code
    guess = [0, 0, 0, 0]
    # initial random guess
    if @guesses_made.size == 0
      guess.clear
      4.times { guess.push(rand(5) + 1) }
    else
      prev_guess = @guesses_made.last
      prev_analysis = @guess_analytics[prev_guess]
      unassigned_positions = [0, 1, 2, 3]

      # set previous "B" matches first
      prev_analysis.each_with_index do |type, index|
        if type == "B"
          guess[index] = prev_guess[index]
          unassigned_positions.delete(index)
        end
      end

      # move "W" matches to a random available position (not a "B" position)
      prev_analysis.each_with_index do |type, index|
        if type == "W"
          position = unassigned_positions.sample()
          guess[position] = prev_guess[index]
          unassigned_positions.delete(position)
        end
      end

      # randomly assign any remaining unassigned positions
      unassigned_positions.each do |position|
        guess[position] = rand(5) + 1
      end
    end
    puts ""
    puts "#{@name} has guessed:"
    p guess
    return guess
  end

end

# The main game mechanisim
class Mastermind

  def initialize(player_name)
    @player = User.new(player_name)
    @computer = Computer.new("Computer")
    @maker = nil
    @breaker = nil
    @game_over = false
    @code = []
  end

  # Initiates the game
  def play_game
    show_instructions
    @maker = set_maker
    @breaker = (@maker == @player) ? @computer : @player
    @code = @maker.create_code
    round = 0
    until (@game_over == true)
      round += 1
      puts "Round #{round}"
      current_guess = @breaker.guess_code
      @breaker.guesses_made.push(current_guess)
      if current_guess == @code
        @game_over = true
        @breaker.winner = true
      else
        @breaker.guess_analytics[current_guess] = analyze_guess
        display_guesses
      end
      if round == 12
        @game_over = true
        @maker.winner = true
      end
    end
    show_winner(round)
  end

  # Sets the roles of the player and computer as "maker" or "breaker"
  # Returns the Player class object that is the "maker" (ie: Player or Computer)
  def set_maker
    begin
      puts ""
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
    puts ""
    puts "#{@player.name} has chosen to be the 'code-#{@player.role}'."
    codemaker = (@player.role == "maker") ? @player : @computer
    return codemaker
  end

  # Returns an array indicating the match-type of each digit in a guess array.
  # For example: ["B", "W", "N", "N"]
  # "B" indicates match of both position and value
  # "W" indicates match of value, but in the wrong position
  # "N" indicates a number that is not found in any position of the secret code.
  def analyze_guess
    analysis = ["N", "N", "N", "N"]
    code_matches = []  # [position in guess array, position in code, match type]

    # check each guess position against all code values, and label match type
    @breaker.guesses_made.last.each_with_index do |num_guess, index_guess|
      @code.each_with_index do |num_code, index_code|
        if (index_guess == index_code && num_guess == num_code)
          code_matches.push([index_guess, index_code, "B"])
        elsif (num_guess == num_code)
          code_matches.push([index_guess, index_code, "W"])
        end
      end
    end

    matches_b = []
    matches_w = []
    # refine list of matches: prioritize "B" matches, and remaining possible "W"
    code_matches.each do |match|
      position_guess = match[0]
      position_code = match[1]
      match_type = match[2]
      # skip if "B" match already found at this guess or code position
      unless (match_nested_array_at_subposition?(matches_b, position_guess, 0) ||
              match_nested_array_at_subposition?(matches_b, position_code, 1))
        case match_type
        when "W"
            matches_w.push(match)
        when "B"
          matches_b.push(match)
          # if "B" match, remove any saved "W" at this guess or code position
          matches_w.each do |w_match|
            if (w_match[0] == position_guess || w_match[1] == position_code)
              matches_w.delete(w_match)
            end
          end
        end
      end
    end
    # add "W" matches to analysis
    # Refine "W" matches and add to analysis (only 1 "W" for any 1 guess position)
    w_guess_positions_assigned = []
    w_code_positions_assigned = []
    matches_w.each do |match|
      position_guess = match[0]
      position_code = match[1]
      match_type = match[2]
      unless (w_guess_positions_assigned.include?(position_guess) ||
              w_code_positions_assigned.include?(position_code))
        analysis[position_guess] = match_type
        w_guess_positions_assigned.push(position_guess)
        w_code_positions_assigned.push(position_code)
      end
    end
    #  add "B" matches to analysis
    matches_b.each { |match| analysis[match[0]] = match[2] }
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

  # Outputs to console a list of all guesses along with the number of
  # Black and White matches
  def display_guesses
    puts "----------------------------------------"
    puts ""
    puts "All guesses made so far, with clues:"
    puts ""
    display_array = []
    @breaker.guesses_made.each_with_index do |guess, index|
      puts "Guess #{(index + 1).to_s}:"
      analysis = @breaker.guess_analytics[guess]
      display_array = [guess,
                      "Black:",
                      analysis.count("B"),
                      "White:",
                      analysis.count("W")]
      p display_array
      puts ""
    end
    puts "=================================================="
  end

  # Displays the winner as console output
  def show_winner(round)
    if @breaker.winner == true
      puts "----------------------------------------"
      puts ""
      puts ""
      puts "#{@breaker.name.upcase} wins after #{round} rounds!!"
    elsif @maker.winner == true
      puts ""
      puts ""
      puts "#{round} rounds have been played, #{@maker.name.upcase} Wins!!"
    else # debug case
      puts "I find it strange that nobody won...perhaps an error..."
    end
    puts ""
    puts "The secret code was:"
    p @code
    puts ""
    puts "=================================================="
  end

  # Displays the instructions as console output
  def show_instructions
    puts ""
    puts "INSTRUCTIONS"
    puts "--------------------------------------------------------------------"
    puts ""
    puts "The code-maker will pick a 4-digit code among the numbers 1 to 6."
    puts "The code-breaker then has 12 chances to guess, or break, the secret"
    puts "code.  After each guess, the code-maker will reveal clues as to how"
    puts "close the guess was."
    puts ""
    puts "A 'Black Match' marker will be presented for each digit that is a"
    puts "correct number in the correct position."
    puts ""
    puts "A 'White Match' marker will be given for each digit that is a"
    puts "correct number, but not in the correct position."
    puts ""
    puts "--------------------------------------------------------------------"
  end

end

# Play single-player game, one user against the computer
game = Mastermind.new("Jason")
game.play_game

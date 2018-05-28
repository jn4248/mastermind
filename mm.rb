

# A player in the game
class Player
  attr_reader :name
  attr_accessor :role, :winner

  def initialize(name)
    @name = name
    @role = ""
    @winner = false
  end

  def guess_code
    puts "========================================="
    begin
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
    # p ["#{@name} has guessed:", guess]
    puts "#{@name} has guessed:"
    p guess
    puts "========================================="
    return guess
  end

end

# Player operated by a human user
class User < Player

  def create_code
    puts "=-----=------=-----=-----=----=------=----=----=-----=----="
    puts "creating code:"
    begin
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
    # p ["#{@name} has entered the secret code:", code]
    puts "#{@name} has entered the secret code:"
    p code
    puts "=-----=------=-----=-----=----=------=----=----=-----=----="
    return code
  end

end

# A Player automated by the computer
class Computer < Player

  def create_code
    puts "=-----=------=-----=-----=----=------=----=----=-----=----="
    puts "creating code:"
    code = []
    4.times { code.push(rand(5)+1) }
    # p code
    puts ""
    puts "=-----=------=-----=-----=----=------=----=----=-----=----="
    return code
  end

end

# The main game mechanisim
class Mastermind

  def initialize(player_name)
    @player = User.new(player_name)
    @computer = Computer.new("Computer")
    @game_over = false
    @code = []
    @guesses_made = []
    @guess_analytics = {}
  end



  # Initiates the game
  def play_game
    # assume roles
    maker = set_maker
    # maker = @computer
    breaker = (maker == @player) ? @computer : @player
    @code = maker.create_code
    round = 0
    until (@game_over == true)
      round += 1
      puts "Round #{round}"
      current_guess = breaker.guess_code
      @guesses_made.push(current_guess)
      if current_guess == @code
        @game_won = true
        breaker.winner = true
      else
        @guess_analytics[current_guess] = analyze_guess
        display_guesses
      end
      if round == 12
        @game_over = true
        maker.winner = true
      end
    end
    show_winner(round, maker, breaker)
  end

  def analyze_guess
    puts "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
    # Record match type: B = position and value, W = value only, N = none
    analysis = ["N", "N", "N", "N"]
    code_matches = []  # [guess position, code position, match type]

    # check each guess position against all code values, and label match type
    @guesses_made.last.each_with_index do |num_guess, index_guess|
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
    puts ""
    puts "Analysis made:"
    p analysis
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

  def display_guesses
    puts "---------------------------------"
    puts "Code is:"
    p @code
    puts ""
    puts "All guesses made so far:"
    puts "Black Match: Correct Number in Correct Position."
    puts "White Match: Correct Number in Wrong Position."
    puts ""
    display_array = []
    count_b = 0
    count_w = 0
    @guesses_made.each_with_index do |guess, index|
      puts "Guess #{(index + 1).to_s}:"
      analysis = @guess_analytics[guess]
      display_array = [guess,
                      "Black:",
                      analysis.count("B"),
                      "White:",
                      analysis.count("W")]
      p display_array
    end
    puts ""
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

  # Displays the winner
  def show_winner(round, maker, breaker)
    if breaker.winner == true
      puts "#{breaker.name} wins after #{round} rounds!!"
    elsif maker.winner == true
      puts "#{round} rounds have been played, #{maker.name} Wins!!"
    else
      puts "I find it strange that nobody won...perhaps an error..."
    end
    puts ""
    puts "The secret code was:"
    p @code
  end

end

# Play single-player game, one user against the computer
game = Mastermind.new("Jason")
game.play_game

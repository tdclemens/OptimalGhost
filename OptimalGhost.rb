# Optimal Ghost
# Author: Tyler Clemens
# Description: Two players build an English word (one player and the computer. Each 
# player adds one letter per turn. If the player completes a word or adds a character
# that makes it impossible to make a word the player looses.

#--------------------------------------------------------------------------------------------------
# SIMPLIFIED ALGORITHM
# 1. get a character
# 2. create a hash table that maps each letter of the alphabet to the beginning character of each
# 	 word in the list of words
# 3. use the character and the hash table to determine if there is a winner or looser
# 4. create a similar hash table with the next character in each word and a new list of words who's
# 	 starting letter is from step 1.
# 5. get a new character
# 6. use the new character and the new hash table to determine if there is a winner or looser
# 7. repeat steps 4 - 7 for the rest of the game (in a simlar fashion to what is written)

#--------------------------------------------------------------------------------------------------
# class: OptimalGhost
# description: This is a class that defines the Optimal Ghost game. My implimentation of Optimal
# Ghost has state and behavior, so I thought it was fitting to use a class. States are the 
# programStep, wordHash, and word. Public behavior at this stage is beginning the game.There are 
# also cool ways that a class could be used to expand functionality. Say there are observers that
# want to see the current state of the running games. Getter methods could be used to retrieve 
# state for example who is winning).
class OptimalGhost
	# constants that define the alphabet
	Alpha  = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s',
			  't','u','v','w','x','y','z']
	#----------------------------------------------------------------------------------------------
	# class: GameTermination
	# description: This class is used to catch winning or loosing of the game. This way if the game
	# is terminated anywhere then an exception can be thrown.
	class GameTermination < Exception
		#------------------------------------------------------------------------------------------
		# method: continue?
		# description: When someone has won the game this method prompts for continuation
		# return: true if playing again. false if not playing again
		def continue?
			puts @msg
			while(true)
				print "Would you like to continue? (Y/N) >> "
				answer = gets.strip!
				if answer.match(/[YyNn]/).nil? or answer.length > 1
					puts "\nplease enter Y or N"
				else
					break
				end
			end
			return answer.match(/[Yy]/).nil? ? false : true
		end
	end
	#----------------------------------------------------------------------------------------------
	# class: GameLost
	# description: an extension of GameTermination that tells the human player he lost and the
	# computer has won
	class GameLost < GameTermination
		def initialize
			@msg = "Computer has won the game!\n"
		end
	end
	#----------------------------------------------------------------------------------------------
	# class: GameWon
	# description: an extension of GameTermination that tells the human player he won and the
	# computer has lost
	class GameWon < GameTermination
		def initialize
			@msg = "You have won the game!\n"
		end
	end
	#---------------------------------------------------------------------------------------------- 
	# method: initialize
	# description: called upon construction by ruby
	def initialize
		$stdout.sync = true # set the standard output sync to true to avoid buffering problems
		file = File.open "words.txt", "r"
		@wordList = file.readline.split(' ')
		raise "words.txt needs to be in the same directory as optimalGhost.rb" if file.nil?
		initialize_game
	end
	#---------------------------------------------------------------------------------------------- 
	# method: begin_match
	# description: its the only public method that starts the game
	def begin_match
		begin
			#to avoid strange scope behavior with the c variable (ruby wont recognize it sometimes)
			c = 'a'
			while (true)
				# Player's turn
				lastC = c unless @programStep == 0
				c = get_character
				lastC = c if @programStep == 0 # set lastC to something first time around
				@wordHash = create_word_hash(@wordHash[lastC], @programStep) unless @programStep.eql? 0
				raise GameLost if @wordHash[c].length < 1
				@word = status_update(@word, c)
				raise GameLost if @wordHash[c].include? @word
				@programStep += 1
				# Computer's turn
				lastC = c
				c = choose_computers_letter(lastC)
				puts "Computer >> #{c}"
				@wordHash = create_word_hash(@wordHash[lastC], @programStep)
				raise GameWon if @wordHash[c].length < 1
				@word = status_update(@word, c)
				raise GameWon if @wordHash[c].include? @word
				@programStep += 1
			end
		rescue GameWon, GameLost => e
			if e.continue?
				initialize_game
				begin_match
			end
		end
	end

	private

	#---------------------------------------------------------------------------------------------- 
	# method: initialize_game
	# description: initializes the game during gameplay
	def initialize_game
		@word = ""
		@programStep = 0
		@wordHash = create_word_hash(@wordList, 0)
		puts "\n####Optimal Ghost####\n"
		puts "About:\nOptimal Ghost is a word game."+
			 " You take turns entering characters with the computer.\n"+
			 "If a word is created that player looses.\n" +
			 "Also, if a word cannot be created after the player enters his character he looses.\n"
	end

	#---------------------------------------------------------------------------------------------- 
	# method: create_word_hash
	# description: it creates a hash whos keys are the alphabet and whos values are arrays of
	# words. The arrays of words are those words that have the key letter as their position at
	# wordIndex
	# arugments:
	# words - an array of words to create the hash from
	# wordIndex - the index in the word that is used to build the values
	def create_word_hash(words, wordIndex)
		wordHash = {}
		Alpha.each {|letter| wordHash[letter] = []}
		for word in words do
			wordHash[word[wordIndex]] << word unless word[wordIndex].nil?
		end
		return wordHash
	end
	#---------------------------------------------------------------------------------------------- 
	# method: choose_computers_letter
	# description: this method chooses a letter for the computer. If the computer thinks it will
	# win it chooses randomly from all the winning moves. Otherwise it selects a random consonant
	# or vowel based on the last character played that will keep the game going.
	# return: value played by the computer
	def choose_computers_letter(lastC)
		winC = computer_thinks_win(lastC)
		looseC = computer_thinks_loose(lastC)
		#first try valuesToChoose
		if !looseC.nil?
			returnC = looseC
		else
			returnC = winC
		end
		if returnC.nil?
			chars = []
			@wordHash[lastC].each { |word| chars << word[@programStep]}
			returnC = chars.sample
		end
		return returnC
	end

	#---------------------------------------------------------------------------------------------- 
	# method: computer_thinks_loose
	# description: evalutates if the computer thinks it will loose
	# return: the character the computer chooses
	def computer_thinks_loose(lastC)
		#the computer should think that its going to loose if program step is on the last character
		wordList = []
		@wordHash[lastC].each{ |word| 
			wordList << word if word.length == @programStep + 1 
		}
		if wordList.nil? or wordList.empty?
			return nil
		else
			# Try to extend the game as long as possible
			countLetters = {}
			noUseLetters = []
			@wordHash[lastC].each { |word|
				hvalue = countLetters[word[@programStep]]
				noUseLetters << word[@programStep] if wordList.include? word
				countLetters[word[@programStep]] = hvalue.nil? ? 0 : hvalue + 1
			}
			countLetters.delete_if {|key,value| noUseLetters.include? key}
			longestLetter = countLetters.empty? ? Alpha.sample : countLetters.keys.sample
			return longestLetter
		end
	end

	#---------------------------------------------------------------------------------------------- 
	# method: computer_thinks_win
	# description: evaluates if the computer thinks it will win
	# return: character to play if the computer can win. Otherwise return nil
	def computer_thinks_win(lastC)
		# The computer should think that it will win if it can choose a character such that its the
		# 2nd to last character of a word
		wordList = []
		@wordHash[lastC].each{ |word| 
			wordList << word if word.length == @programStep + 2
		}
		if wordList.nil? or wordList.empty?
			return nil
		else
			return wordList.sample[@programStep]
		end
	end

	#---------------------------------------------------------------------------------------------- 
	# method: get_character
	# description: prompts the human user for a character and returns it. handles input cases
	# return: the character entered by the user
	def get_character
		while(true)
			print "\nPrompt >> "
			c = gets.strip.downcase
			if c.match(/[A-Za-z]/).nil? or c.length > 1
				puts "\nplease enter one letter(a-z)"
			else
				break
			end
		end
		return c
	end

	#---------------------------------------------------------------------------------------------- 
	# method: status_update
	# description: prints the updated word
	# return: the new word with the added character
	def status_update(word, c)
		word += c
		puts "word is now: #{word}"
		return word
	end
end

# Run the program
game = OptimalGhost.new
game.begin_match

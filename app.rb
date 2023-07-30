require "sinatra"
require "sinatra/reloader"
require "http"
require "discordrb"

# Fetch keys from the environment
SCRABBLE_API_KEY = ENV.fetch("SCRABBLE_API_KEY")
BOT_TOKEN = ENV.fetch("BOT_TOKEN")

# Create Discord bot instance
bot = Discordrb::Bot.new(token: BOT_TOKEN)

# Event handler for the bot's 'message' event
bot.message do | event |

  ## Check if the message is from the bot itself
  next if event.author.bot_account?
  
  ## Get the word from user's message
  word = event.message.content.downcase
  
  ## Query API for word
  result = word_check(word)

  ## Create embed for bot's response
  embed = Discordrb::Webhooks::Embed.new

  ## Fetch message from event to reference in the reply
  message = event.message
  
  ## Send the appropriate reply
  if result == 0 
    ### Word not found
    embed.color = 0xe0322f
    embed.title = "You are so creative!"
    embed.description = "But that is not a Scrabble word... "
    event.message.reply!("", tts: false, embed: embed)
  elsif result == nil
    ### Error case
    embed.color = 0x000000
    embed.title = "🙈 The dog ate my dictionary... 📖 🐕"
    embed.description = "Sorry! Something went wrong with the search. Please try again later."
    event.message.reply!("", tts: false, embed: embed)
  else 
    ### Word found
    embed.title = "It's a word!"
    embed.description = "#{word.capitalize} will earn you #{result} points."
    embed.color = 0x12b371 
    event.message.reply!("", tts: false, embed: embed)
  end
end


# Start the bot in a separate thread and listen for messages
Thread.new { bot.run }

# Helper method to query the API
def word_check(word)
  ## Construct URL
  url = "https://scrabble-api.fly.dev/api/word/#{word}"

  ## Ensure input does not contain invalid characters
  if word.match(/\A[a-zA-Z]+\z/) 
    begin
      response = HTTP.auth("Bearer #{SCRABBLE_API_KEY}").get(url).to_s
      parsed_response = JSON.parse(response)
      
    rescue StandardError => e ### Handle parsing/network errors
      puts "There was an error :( #{e.message}"
      parsed_response = nil
    end
    ### Return word score if found, 0 if not found
    search_result = parsed_response.is_a?(Integer) ? parsed_response : 0
  else
    ### Word contains invalid characters
    search_result = 0
  end
end

# Render home route
get("/") do
  erb(:home)
end

# Render results page
get("/check") do
  
  ## Get user input
  @word = params.fetch("word").downcase
  
  ## Query API for word
  @result = word_check(@word)

  ## Render error template if necessary
  if @result == nil
    erb(:error)
  ## Render results page
  else
    erb(:check)
  end
end

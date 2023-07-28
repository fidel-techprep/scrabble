require "sinatra"
require "sinatra/reloader"
require "http"
require "ox"
require "discordrb"


SCRABBLE_API_KEY = ENV.fetch("SCRABBLE_API_KEY")
BOT_TOKEN = ENV.fetch("BOT_TOKEN")


bot = Discordrb::Bot.new(token: BOT_TOKEN)

# Event handler for the 'message' event
bot.message do |event|
  
  # Check if the message is from the bot itself to avoid infinite loops
  next if event.author.bot_account?
  server = bot.server(1133097855402381342)
  
  word = event.message.content.downcase
  
  result = word_check(word)

  embed = Discordrb::Webhooks::Embed.new
  message = event.message
  

  if result == 0
    embed.color = 0xe0322f
    embed.title = "You are so creative!"
    embed.description = "But that is not a Scrabble word... "
    event.message.reply!("", tts: false, embed: embed)
  else
    embed.title = "It's a word!"
    embed.description = "#{word.capitalize} will earn you #{result} points."
    embed.color = 0x12b371 

    event.message.reply!("", tts: false, embed: embed)
  end
end




# Start the bot and wait for messages
Thread.new { bot.run }


def word_check(word)
  url = "https://www.wordgamedictionary.com/api/v1/references/scrabble/#{word}?key=#{SCRABBLE_API_KEY}"

  if word.match(/\A[a-zA-Z]+\z/) 
    begin
      response = Ox.load(HTTP.get(url).to_s, mode: :hash)[:entry]
    
    rescue StandardError => e
      puts "<div>There was an error :( #{e.message}</div>"
      response = {:scrabblescore => 0}
    end
    
    search_result = response[:scrabble] == "0" ? 0 : response[:scrabblescore] 
  else
    search_result = 0
  end
end

get("/") do
  erb(:home)
end

get("/check") do
  @word = params.fetch("word").downcase
  @result = word_check(@word)
  
  erb(:check)

end

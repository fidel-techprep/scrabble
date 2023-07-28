require "sinatra"
require "sinatra/reloader"
require "http"
require "discordrb"


# hide key
# test user joining
# add attribution and links to html pages
SCRABBLE_API_KEY = ENV.fetch("SCRABBLE_API_KEY")
BOT_TOKEN = ENV.fetch("BOT_TOKEN")


bot = Discordrb::Bot.new(token: BOT_TOKEN)


bot.member_join do |event|
  sleep(1)
  # Get the new member that joined the server
  new_member = event.user
  
  embed = Discordrb::Webhooks::Embed.new
  embed.title = "Welcome to Scrabble Word Check, #{new_member.username}!"
  embed.description = "Powered by [Wordnik](http://www.wordnik.com)"
  #embed.thumbnail = {url: "https://www.wordnik.com/img/wordnik_gearheart.png"}
  embed.footer =  {
    "icon_url": "https://www.wordnik.com/img/wordnik_gearheart.png",
    "text": "‏‏‎ ‎"
  }


  # Replace 'YOUR_WELCOME_MESSAGE' with the desired welcome message

  # Replace 'TARGET_CHANNEL_ID' with the ID of the channel where you want to send the welcome message
  target_channel_id = 1133097856610345101

  # Send the welcome message to the specified channel
  bot.send_message(target_channel_id, '', tts = false, embed = embed)
end


# Event handler for the 'message' event
bot.message do |event|
  # Check if the message is from the bot itself to avoid infinite loops
  next if event.author.bot_account?
  server = bot.server(1133097855402381342)
  pp server.channels
  word = event.message.content.downcase
  
  result = word_check(word)

  link = "https://www.wordnik.com/words/#{word}"
  embed = Discordrb::Webhooks::Embed.new
  message = event.message
  pp word
  pp result

  if result == 0
    embed.color = 0xe0322f
    embed.description = "You are so creative! But that is not a scrabble word... "
    event.message.reply!("", tts: false, embed: embed)
  else
    embed.title = "It's a word!"
    embed.description = "[#{word.capitalize}](https://www.wordnik.com/words/#{word}) will earn you #{result} points."
    embed.color = 0x12b371 

    # Send the embed as a message
    #event.send_embed('', embed)
    event.message.reply!("", tts: false, embed: embed)
  end
end




# Start the bot and wait for messages
Thread.new { bot.run }



#server 1133097855402381342
# channel 1133097856610345101





def word_check(word)
  url = "https://api.wordnik.com/v4/word.json/#{word}/scrabbleScore?api_key=#{SCRABBLE_API_KEY}"

  if word.match(/\A[a-zA-Z]+\z/) 
    begin
      response = JSON.parse(HTTP.get(url))
      pp response
    rescue StandardError => e
      puts "<div>There was an error :( #{e.message}</div>"
      response = {"value" => "There was an error :(" }
    end
    pp response
    search_result = !response["value"] ? 0 : response["value"] 
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
  #if word_check(@word) == nil
   #"<div>No spaces, symbols or digits allowed :(</div>
  #<a href=\"/\" >Go back</a>" 
  #else
    erb(:check)
  #end
end

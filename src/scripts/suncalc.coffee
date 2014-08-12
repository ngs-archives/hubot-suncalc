# Description:
#   Replies sunrise and sunset of the day for given location.
#
# Configuration:
#   HUBOT_GOOGLE_API_KEY (optional)
#
# Commands:
#   hubot sunrise <location> - Replies sunrise of the date.
#   hubot sunset <location> - Replies sunset of the date.
#   hubot moonphase - Replies moonphase of the date.

API_BASE = 'https://maps.googleapis.com/maps/api/'
SunCalc = require 'suncalc'
moons = [
  "\uD83C\uDF18"
  "\uD83C\uDF17"
  "\uD83C\uDF16"
  "\uD83C\uDF15"
  "\uD83C\uDF14"
  "\uD83C\uDF13"
  "\uD83C\uDF12"
  "\uD83C\uDF11"
]

module.exports = (robot)->

  zeropad = (n)->
    if n < 10 then "0#{n}" else "#{n}"

  formatTime = (date, { rawOffset, timeZoneName })->
    h = date.getHours()
    m = date.getMinutes()
    t = h * 60 + m + rawOffset / 60 + date.getTimezoneOffset()
    h = Math.floor(t / 60)
    h -= 24 if h >= 24
    h += 24 if h < 0
    m = t % 60
    ap = if h < 12
      'AM'
    else
      h -= 12
      'PM'
    "#{ zeropad h }:#{ zeropad m } #{ap}"

  getLocation = (locationName, msg, callback)->
    apiKey = process.env.HUBOT_GOOGLE_API_KEY
    keyParam = if apiKey? then "&key=#{apiKey}" else ''
    found = (loc)->
      { lat, lng } = loc.geometry.location
      now = new Date()
      times = SunCalc.getTimes now, lat, lng
      tzURL = "#{API_BASE}timezone/json?language=en&location=#{lat}%2C#{lng}&timestamp=#{now.getTime() / 1000}#{keyParam}"
      try
        robot.http(tzURL).get() (err, res, body)->
          try
            body = JSON.parse body
            callback.call this, loc.formatted_address, times, body
          catch e
            msg.reply e.message
      catch e
        msg.reply e.message

    try
      locURL = "#{API_BASE}geocode/json?language=en&address=#{locationName}#{keyParam}"
      robot.http(locURL).get() (err, res, body)->
        try
          body = JSON.parse body
          results = body?.results || []
          len = results.length
          if len == 1
            found results[0]
          else if len > 1
            text = [
              "Found #{len} locations for \"#{locationName}\"."
              'Answer leading index number:'
            ]
            for loc, index in results
              text.push "#{ index + 1 }. #{ loc.formatted_address }"
            fn = (msg2)->
              user  = msg.message?.user  || msg.envelope?.user
              user2 = msg2.message?.user || msg2.envelope?.user
              return unless user.id is user2.id
              index = robot.listeners.indexOf listener
              robot.listeners.splice index, 1
              i = msg2.match[0].trim()
              if loc = results[parseInt(i) - 1]
                found loc
              else
                msg2.reply "No location at index #{i}."
            robot.hear /\s*(\d+)/, fn
            listener = robot.listeners[robot.listeners.length - 1]
            msg.reply text.join "\n"
        catch e
          msg.send e.message
    catch e
      msg.send e.message

  robot.respond /\s*sunrise\s+(.+)\s*$/i, (msg)->
    locationName = msg.match[1].trim()
    getLocation locationName, msg, (formattedAddress, { sunrise }, timezone)->
      msg.send "Sunrise in #{formattedAddress} is #{ formatTime sunrise, timezone }"

  robot.respond /\s*sunset\s+(.+)\s*$/i, (msg)->
    locationName = msg.match[1].trim()
    getLocation locationName, msg, (formattedAddress, { sunset }, timezone)->
      msg.send "Sunset in #{formattedAddress} is #{ formatTime sunset, timezone }"

  robot.respond /\s*moonphase\s*$/i, (msg)->
    { phase } = SunCalc.getMoonIllumination new Date()
    i = Math.floor(moons.length * phase)
    msg.send "#{moons[i]}  #{Math.round(phase * 10000)/100}%"


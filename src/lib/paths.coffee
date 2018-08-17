module.exports = 
	
paths = (urlStrings) ->  # TACTICAL
  urlStrings.map (s) ->
    s2 = s.replace(/^file:\/\//, "")  # file:///xyz -> /xyz
    #   .replace("\"", "\\\"")  # quote '"'
    # return "\"#{s2}\""  # "/xyz"

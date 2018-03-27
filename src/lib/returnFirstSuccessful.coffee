module.exports = 
  (fns) ->
    i = 0
    exceptions = []
    while i < fns.length
      fn = fns[i]
      try
        if fn.callAsFunction
          return fn.callAsFunction()
        else
          # debugger
          return fn.apply()
      catch e
        # this function threw -- move on to the next one.
        exceptions.push(e)
      i++
    debugger
    throw Error("cx-jxa: no calls were successful. exceptions: #{toString(exceptions)}")
    # TODO collect the exceptions for better debuggability.


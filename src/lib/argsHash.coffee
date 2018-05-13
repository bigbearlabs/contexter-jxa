# return a dictionary of args conventionally passed as an array of strings,
# based on common sense expectations.
module.exports = argsHash = (argv) ->
  # for each bit, split to <key>=<value>, to return a k-v pair.
  # reduce it down to a pojo and return.

  argsObj = argv.reduce (acc, token) ->
    [k, v] = token.split(/=(.+)/)  # decompose first k=v into a kv pair.
    acc[k] = v
    acc
  , {}

  return argsObj


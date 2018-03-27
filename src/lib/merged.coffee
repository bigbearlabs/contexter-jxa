module.exports = merged = (objA, objB) ->

  cloned = Object.assign {}, objA
  merged = Object.assign cloned, objB
  return merged

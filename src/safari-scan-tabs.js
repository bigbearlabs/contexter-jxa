let argsHash = require('./lib/argsHash')


global.main = (argv) => {

  let args = argsHash(argv)

  let windowId = args.windowId
  let titlePattern = args.titlePattern

  let w = Application("com.apple.Safari").windows().find( w => w.id() == windowId )
  if (w == null) {
    throw `window not found for id ${windowId}`
  }

  let originallyActiveTabIndex = (_activeTabIndex(w) || [null, 0])[1]
  let nullUrlIndexes = _nullUrlIndexes(w, titlePattern)

  for (let i of nullUrlIndexes) {
    doActivateSafariTab(w, i)
    // delay(1)
  }

  doActivateSafariTab(w, originallyActiveTabIndex)

  sleep(100)
  
  let scannedTabs = nullUrlIndexes.map( i => {
    return {
      index: i,
      url: w.tabs[i].url()
    }
  })

  // TODO return result to stdout.
  return JSON.stringify({
    windowId: windowId,
    activeTabIndex: originallyActiveTabIndex,
    scannedTabs: scannedTabs
  })
}


// side-effecting functions

function doActivateSafariTab(w, i) {
  let tab = w.tabs()[i]
  w.currentTab = tab
}


// deriver functions

function _nullUrlIndexes(w, titlePattern) {
  
  let tabsData = w.tabs().map( (t, i) => {
    if (titlePattern == null) {
      return [t, i, true]
    }

    let title = t.name()
    let pattern = new RegExp(titlePattern) 
    return [t, i, title.match(pattern) != null]
  })

  let nullUrlIndexes = tabsData
    .filter( e => e[2] == true && e[0].url() == null )
    .map( e => e[1] )

  return nullUrlIndexes
}

function _activeTabIndex(w) {
  let activeIndexTuples = w.tabs().map((t, i) => [t.visible(), i])
  return activeIndexTuples
    .find( t => t[0] == true )
}


// util functions

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

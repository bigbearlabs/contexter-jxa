/* jshint strict: true, asi: true, newcap: false */
/* jshint -W087 */


// ---
// doit: |
//   `cat #{file} | osascript -l JavaScript`
// ---


function run(argv) {
    'use strict';


    var app = argv[0]
    var filter_window_id = argv[1]


    // TEST VALUES uncomment lines and run without any params to test the script on a specific app.
    if (argv.length === 0 || !app || app === '') {

        app = "com.apple.Safari"
        // app = "com.apple.Finder"
        // app = "com.google.Chrome.canary"
        // app = "com.torusknot.SourceTreeNotMAS"
        // app = "com.apple.spotlight"
        // app = "com.apple.dt.Xcode"
        // app = "com.apple.iWork.Keynote"
        // app = "com.apple.iWork.Numbers"

        // filter_window_id = 15248
    }


    try {
        return read_windows1(app, filter_window_id)
    } catch (e) {
        debugger
        
        // try the fallback using system events.
        return read_windows2(app)
    }



// read window info using the app's applescript dictionary.
function read_windows1(app_name, filter_window_id) {

    var application = Application(app_name)
    
    // array of windows containing elements (window_id, url, name).
    var elementsArray = application.windows().map(read_window_info)

    // convert into a map.
    var windows = elementsArray.map(function(elements) {
        // console.log(JSON.stringify(Object.getOwnPropertyNames(e)))
        // return 1
        var anchor

        if (elements.length > 1) {
            anchor = elements.find(function(e) {
                if (e && e.current) {
                    return e.current
                } else {
                    // FIXME why would elem end up being null?
                    return false
                }
            })
        } else {
            anchor = elements[0]
        }

        return {
            elements: elements,
            anchor: anchor
        }
    })

    if (filter_window_id) {
        windows = windows.filter(function(w) {
            return w.elements[0].window_id == filter_window_id
        })
    }

    // result
    return JSON.stringify({
        windows: windows
    })
}

function read_window_info(w) {
    try {
        var elements = returnFirstSuccessful([
            // various strategies to obtain elements of the window.

            // finder
            function() { return [ w.target() ] },

            // safari, chrome
            function() {

                // return w.tabs().map(function(e) {
                //     var isCurrent = (visibleTabIndex == e.index())
                //     return {
                //         name: e.name(),
                //         url: e.url(),

                //         window_id: w.id(),
                        
                //         current: isCurrent,
                //         tab_index: e.index(),
                //     }
                // })

                return w.tabs()
            },

            // normal doc apps
            function() { return [ w.document() ] },
        ])

        var element_data = returnFirstSuccessful([
            // finder, safari, chrome.
            function() {
                 var visibleTabIndex;
                 try {
                     if (w.currentTab) {
                         visibleTabIndex = w.currentTab().index()
                     } 
                     else if (w.activeTab) {
                         // for chrome, use activeTab instead.
                         visibleTabIndex = w.activeTab().index() 
                     }
                 } catch (e) {
                    // finder ends up here, among other things.
                 }

                return elements.map( function(element) {
                    var index, isCurrent;
                    if (element.index) {
                        index = element.index()
                        isCurrent = (visibleTabIndex == index)
                    }

                    return {
                        name: element.name(),
                        url: element.url(),

                        window_id: w.id(),

                        current: isCurrent,
                        tab_index: index
                    }
                })
            },
            // keynote.
            function() {
                return elements.map( function(element) {
                    return {
                        url: element.file().toString(),
                        name: element.name(),

                        window_id: w.id()
                    }
                })
            },
            // xcode.
            function() {
                return elements.map( function(element) {
                    return {
                        name: element.fileReference.name()[0],
                        url: element.fileReference.fullPath()[0],

                        window_id: w.id()
                    }
                })
            },
        ])

        // debugger
        
        return element_data
    }
    catch (e) {
        debugger
        
        return [{
            err: e.toString(),
            window_id: w.id(),
            window_name: w.name(),
        }]
    }
}



// read using system events.
// adapted from https://forum.keyboardmaestro.com/t/path-of-front-document-in-named-application/1468
// NOTE this will scope windows to current space only!
function read_windows2(bundle_id) {

    var app_name = Application(bundle_id).name()    /* jshint newcap:false */
    
    var appSE = Application("System Events"),
        appNamed = null,
        lstWins = null,
        strPath = '',
        lngPrefix, strURL;

    appNamed = appSE.applicationProcesses[app_name];
    // IS THERE AN OPEN WINDOW IN AN APPLICATION OF THIS NAME ?
    try {
        lstWins = appNamed.windows();
    } catch (f) {
        return JSON.stringify({
            err: 'e1: No open documents found in ' + app_name
        })
    }

    if (lstWins) {
        // DOES THE WINDOW CONTAIN A SAVED DOCUMENT ?
        try {
            strURL = lstWins[0].attributes["AXDocument"].value();
        } catch (g) {
            return JSON.stringify({
                err: 'e2: No open documents found in ' + app_name
            })
        }
    }

    var windows = lstWins.map(function(w0) {
        return {
            url: w0.attributes["AXDocument"].value(),
            name: w0.attributes["AXTitle"].value(),
            // window_id: 'x'  // how are we going to get this?
            
        }
    })

    return JSON.stringify({
        windows: [
            {
                elements: windows,
                anchor: windows[0]
            }
        ]
    })
}



function returnFirstSuccessful(fns) {
    for (var i = 0; i < fns.length; i++) {
        var fn = fns[i]
        try {
            if (fn.callAsFunction) {
                return fn.callAsFunction()
            } else {
                // debugger
                return fn.apply()
            }
        } catch (e) {
          // this function threw -- move on to the next one.
        }
    }

    throw "no calls were successful."
}

}

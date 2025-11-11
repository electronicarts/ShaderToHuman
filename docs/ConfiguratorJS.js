// todo:
// * compare different configs
// * indentation seems clumsy

// IIFE to wrap global variables / Module Pattern
var Configurator = (function () {
    // private: ------------------------

    // in pixels
    const indentationScale = 35;
    //
    var first = true;
    //
    var currentConfig = "";

    function getIndentationScale() {
        return indentationScale;
    }
    function getTodoTxt() {
        // user facing string
        return "?";
    }
    function getAndSetFirst()
    {
        if(first) {
            first = false;
            return true;
        }

        return false;
    }
    function setConfig(name)
    {
        currentConfig = name;
    }
    function getConfig(name)
    {
        return currentConfig;
    }

    // public: ------------------------
    return {
        // IIFE immediately invoked function expressions
        getIndentationScale : getIndentationScale,
        getTodoTxt : getTodoTxt,
        getAndSetFirst : getAndSetFirst,
        setConfig : setConfig,
        getConfig : getConfig,
    };

})(); // IIFE to wrap global variables end

// needed during ImmediateMode processing, todo: rename
var imTxt = new String();
// needed during ImmediateMode processing
var g_imCanvas = new String();

// in pixels
var indentation = 0;
const validConfig = new Set();

// [key] = value
// e.g. ["ZBuffer/Format"]="R32"
const config = new Map();

// e.g. "MMG1"="ZBuffer=R32\nStencil = no\nTiles = no", ...
const state = new Map();

// e.g. "FlagsInShaderToy.hlsl" = " float3 japan(float2 uv) { ..."
const g_HLSLInputCode = new Map();

// Note: This function is different when run from NodeJS.
// @param filename e.g. "docs/docs/intro_0.glsl" or "docs/docs/intro_0.hlsl"
// @return source code as string
function readCodeFile(filename){
    var code = null;

    if(typeof filename != "string"){
        throw new Error(`Unexpected type for filename: ${typeof filename}. Expecting 'string'`);
    }

    filename = filename.replaceAll('/', '\\');
    filename = filename.toLowerCase();

    for (let [key, val] of g_HLSLInputCode) {
            fullpath = key.toLowerCase();
            if(fullpath.includes(filename)){
                code = val;
                break;
            }  
    }

	assert(code != null, "File not found: '" + filename + "'");
    return code;
}

function importLocalFile() {
    const input = document.getElementById("loadConfigAsTxt");
    console.log("importLocalFile: '" + input.value + "'");
}


// when a config button is clicked
// @param name e.g. "MMG1"
function onConfigButton(name) {
//    console.log("onConfigButton: '" + name + "'");

    Configurator.setConfig(name);

    config.clear();
    var el = state.get(name);
    if (!el)
    {
        console.error("onConfigButton: '" + name + "' failed");
        return;
    }

    var lines = el.split('\n');
    lines.forEach(function (line) {
        var pos = line.indexOf("#");
        if (pos >= 0) {
            // ignore leading space
            if (line[pos + 1] == " ")
                ++pos;
            // e.g. #   my comment goes here
            var value = line.slice(pos + 1);
            var oldValue = "";
            if (config.has("#Comments"))
                oldValue = config.get("#Comments") + "\n";
            set("#Comments", oldValue + value);
        }
        else {
            pos = line.indexOf("=");
            if (pos >= 0) {
                var key = line.slice(0, pos - 1).trim();
                var value = line.slice(pos + 1).trim();

                // e.g. set("LayerCompositing/OutOfSpaceStrategy", "drop_furthest");
                set(key, value);
                // for debugging
                //                    console.log("key: '" + key + "'");
                //                    console.log("value: '" + value + "'");
            }
        }
    })
    print();
}

function isConfigSet(name) {
    var el = state.get(name);
    if (!el) {
        return false;
    }

    if(name === 'X')
        return false;

    // Show if this config was chosen but don't show if the settings have been changed to no longer fit to the config.
    var ret = name === Configurator.getConfig(name);

    var lines = el.split('\n');
    lines.forEach(function (line) {
        var pos = line.indexOf("#");
        if (pos < 0) {
            pos = line.indexOf("=");
            if (pos >= 0) {
                var key = line.slice(0, pos - 1).trim();
                var value = line.slice(pos + 1).trim();

                // e.g. set("LayerCompositing/OutOfSpaceStrategy", "drop_furthest");
                if (validConfig.has(key) && config.get(key) != value)
                    ret = false;
            }
        }
    })

    return ret;
}

function areChoicesValid(arr) {
    let isValid = true;
    arr.forEach(str => {
        // Check if the character is between 'a' and 'z' or 'A' and 'Z'
        if (!/^[a-zA-Z0-9_ ]+$/.test(str)) {
            isValid = false;
        }
    });
    return isValid;
}
// add a option with the UI like a bar of tabs
// e.g. option("ZBuffer/Format", "comment", "R16|R32|R24G8")
// @param choices "|"" separated list made from valid characters, see 
// @return if this option is true, if you want to test for other settings use test(key,value)
function tab(key, commentTxt, choices) {
    //    option(key, commentTxt, choices);

    // todo: remove redundant code with option()

    // inefficient
    const choiceValueArray = choices.split("|");

    if(!areChoicesValid(choiceValueArray))
    {
        console.error("choices '" + choices + "' are not valid");
        return;
    }

    // null if not set
    const userChoice = config.has(key) ? config.get(key) : null;

    validConfig.add(key);

    if (userChoice && !choiceValueArray.includes(userChoice)) {
        // this option does not have the choice slected by the user, maybe a later option call prrovides it,
        // if not we report this as error later
        return false;
    }

    logTab(key, commentTxt, choiceValueArray);

    if (choiceValueArray.length == 1)
        return userChoice == choices;

    return userChoice == "true";
}

function declareKey(key) {
    console.assert(key != null);
    validConfig.add(key);
}

// add a option with the UI like a combo box
// e.g. option("ZBuffer/Format", "comment", "R16|R32|R24G8")
function option(key, commentTxt, choices = "false|true") {
    // inefficient
    const choiceValueArray = choices.split("|");
    // null if not set
    const userChoice = config.has(key) ? config.get(key) : null;

    declareKey(key);

    if (userChoice && !choiceValueArray.includes(userChoice)) {
        // this option does not have the choice slected by the user, maybe a later option call prrovides it,
        // if not we report this as error later
        return;
    }

    logOption(key, commentTxt, choiceValueArray);
}

function test(key, value = "true") {
    console.assert(value != null);
    if (!config.has(key))
        return false;
    return config.get(key) == value;
}

// see set()
// @param key case sensitive e.g "group/name" or "name"
// @return null if not found
function get(key) {
    console.assert(validConfig.has(key), "get(\""+ key + "\") not found");
    if (!config.has(key))
        return null;
    return config.get(key);
}

// see get()
// @param key case sensitive e.g "group/name" or "name"
function set(key, value = "true") {
    if (value == Configurator.getTodoTxt())
        config.delete(key);
    else {
        config.set(key, value);
    }
}

function comment(txt) {
    // inefficient
    if (test("#Comments", "false"))
        return;

    logInfo(txt);
}

function indent(delta) {
    indentation += delta * Configurator.getIndentationScale();
    console.assert(indentation >= 0);
}

function preProcessText(txt)
{
    // to make \n in text a line break
    return txt.replace(/\n/g, "<br />");
}

// large headline
function logH1(txt) {
    txt = preProcessText(txt);
    imTxt += '<p style="margin: 2px; margin-left: ' + indentation + 'px; line-height: 1.5; border-width: 0px; border-style: solid; border-color: #888888; padding: 4px; ">'
    imTxt += '<h1>' + txt + '</h1>';
    imTxt += "</p>\n";
}
// small headline
function logH2(txt) {
    txt = preProcessText(txt);
    imTxt += '<p style="margin: 2px; margin-left: ' + indentation + 'px; line-height: 1.5; border-width: 0px; border-style: solid; border-color: #888888; padding: 4px; ">'
    imTxt += '<h2>' + txt + '</h2>';
    imTxt += "</p>\n";
}

// text without a box around it
function logText(txt) {
    txt = preProcessText(txt);
    imTxt += '<p style="margin: 2px; margin-left: ' + indentation + 'px; line-height: 1.5; border-width: 0px; border-style: solid; border-color: #888888; padding: 4px; ">'
    imTxt += txt;
    imTxt += "</p>\n";
}

// image
// @param src e.g. "test.gif"
// @param alt optional text shown if image cannot be loaded
function logImage(src, alt) {
    if(!alt)
        alt = src; 
	imTxt += '<img src="' + src + '" style="width:75%; height:75%;" alt="' + alt + '"></img>\n'
}


// text with syntax highlighting
function logCode(txt) {
    imTxt += '<pre id="LogCode" style="margin: 2px; margin-left: ' + indentation + 'px;"><code class="language-cpp">'
    imTxt += hljs.highlight(txt, { language: 'cpp' }).value;
    imTxt += '</code></pre>\n';
}

// single quote string
// txt -> "txt"
function quoteString(name) {
    return "'" + name + "'";
}

// text in a grey box
function logInfo(txt) {
    txt = preProcessText(txt);
    imTxt += '<p class="Info" style="margin-left: ' + indentation + 'px;">'
    imTxt += txt;
    imTxt += "</p>\n";
}

// non proportional = fixed-width font in a grey box
function logTxtFile(txt) {
    txt = preProcessText(txt);
    imTxt += '<p class="txtFile" style="margin-left: ' + indentation + 'px;">'
    imTxt += txt;
    imTxt += "</p>\n";
}

function logError(txt) {
    txt = preProcessText(txt);
    imTxt += '<p class="Error" style="margin-left: ' + indentation + 'px;">'
    imTxt += txt;
    imTxt += "</p>\n";
}

// @param name e.g. "Seed webpage"
// @param link e.g. "https://www.ea.com/seed"
function logLink(name, link) {
    imTxt += '<a href ="' + link + '" style="margin-left: ' + indentation + 'px;">' + name + '</a>\n';
}

// only called by option(), call option() instead
// @param choiceValueArray = choices.split("|");
function logOption(key, commentTxt, choiceValueArray) {
    imTxt += '<a class="option" style="margin-left: ' + indentation + 'px;">'

    if (commentTxt)
        imTxt += "<a title=\"* " + commentTxt + "\">" + key + "*</a>";
    else
        imTxt += key;

    imTxt += " = ";

    const keyInQuotes = "\"" + key + "\"";

    // null if not set
    const userChoice = config.has(key) ? config.get(key) : null;

    {
        // combo box start
        imTxt += "<select id=" + keyInQuotes;
        //            if (!userChoice)
        //                imTxt += "style = \"background-color: yellow\"";
        imTxt += " onChange=\"setUI(this.id);\">";

        choiceValueArray.unshift(Configurator.getTodoTxt());

        choiceValueArray.forEach(function (choiceValue) {
            const choiceValueInQuotes = "\"" + choiceValue + "\"";

            // combo box
            imTxt += "<option value=" + choiceValueInQuotes
            if (userChoice == choiceValue)
                imTxt += "selected = \"selected\"";
            imTxt += ">" + choiceValue;
            imTxt += "</option>";
        })
        // combo box end
        imTxt += "</select>\n"

        // highlight what user needs to specify
        if (!userChoice)
            imTxt += "<a style=\"background-color: YELLOW;\"><<<<a>";
    }

    imTxt += "</a><br>\n";
}


// only called by tab(), call tab() instead
// @param choiceValueArray = choices.split("|");
function logTab(key, commentTxt, choiceValueArray) {
    // null if not set
    const userChoice = config.has(key) ? config.get(key) : null;

    logText("");

    var i = 0;
    choiceValueArray.forEach(function (choiceValue) {
        var id = key + 'Is' + i;
        var checked = userChoice == choiceValue ? " checked" : ""; // todo 
        imTxt += '<input type="radio" class="tabChoice" id="' + id + '"' + checked + ' name="' + key + '"';
        imTxt += ' value="' + choiceValue + '"';
        imTxt += ' onChange="onTabUI(this.id);"';
        imTxt += '>';
        imTxt += '<label for="' + id + '">';
        imTxt += choiceValue;
        imTxt += '</label>\n';
        ++i;
    })
//    imTxt += '=' + key;
    imTxt += '<hr style="margin:0px">\n';
//    imTxt += '</br>\n';
}

// ---------------------------

function resetUI() {
    config.clear();
    set("#Comments", "true");
    refreshUI();
}

function extractDataFromHTML() {
    {
        // find all <code> element class="HLSLInputCode"
        // and extra the data to make buttons to set the state on pressing this button
        var elements = document.getElementsByClassName("HLSLInputCode");
        for (var i = 0; i < elements.length; i++) {
            var item = elements.item(i);
            // e.g. MMG1
            var name = item.getAttribute("name");
//            console.log(">>> HLSLInputCode " + name);
            // e.g.
            //  "\tfloat3 japan(float2 uv)\n
            //  {...
            var lines = item.innerHTML;

            // todo: remove leading tabs / spaces
            g_HLSLInputCode.set(name, lines);
        }
        // delete this way to not cause problems for iteration
        while (elements.length) {
            elements.item(0).remove();
        }
    }

    {
        // find all <code> element class="ConfiguratorState"
        // and extra the data to make buttons to set the state on pressing this button
        var elements = document.getElementsByClassName("ConfiguratorState");
        for (var i = 0; i < elements.length; i++) {
            var item = elements.item(i);
            // e.g. MMG1
            var name = item.getAttribute("name");
//            console.log(">>> ConfiguratorState " + name);
            // e.g.
            //  "Topic=RenderPipeline\n
            //   Comments = true\n
            //   Resolution = 1080p\n"
            var lines = item.innerHTML;
            // add the stat entry
            state.set(name, lines);
        }
        // not needed as CSS can hide that without a flicker on startup
        // see code.ConfiguratorState in.css
        // delete this way to not cause problems for iteration
//        while (elements.length) {
//            elements.item(0).remove();
//        }
    }
//    makeConfigButtons();
}

function makeConfigButtons() {
    // remove element by class name
//    var elements = document.getElementsByClassName("StateButtons").item;
//    while (elements.length > 0) elements[0].remove();

    var stateButtons = document.getElementsByClassName("StateButtons").item(0);

    stateButtons.style.display = (state.size == 0) ? "none" : "block";

//    stateButtons.innerHTML = 'Configs: ';

    state.forEach(function (lines, name) {

        const cls = isConfigSet(name) ? "activeConfig" : "config";

        stateButtons.innerHTML += '<button class="' + cls + '" onclick="onConfigButton(\'' + name + '\')">' + name + '</button> ';
//        stateButtons.innerHTML += '<button class="' + cls + '">' + name + '</button> ';
     })
}

function refreshUI() {
    print();
}

function onTabUI(id) {
    const key = document.getElementById(id).name;
    const value = document.getElementById(id).value;

    set(key, value);
    print();
}
function setUI(id) {
    const key = id;
    const value = document.getElementById(id).value;

    set(key, value);
    print();
}

const copyButtonLabel = "Copy Code";

async function copyCode(block, button) {
    let code = block.querySelector("code");
    let text = code.innerText;
  
    await navigator.clipboard.writeText(text);
  
    // visual feedback that task is completed
    button.innerText = "Code Copied!";
  
    setTimeout(() => {
      button.innerText = copyButtonLabel;
    }, 700);
  }

// also validates config
function print() {
    imTxt = "";
    imCode = "";
    g_imCanvas = ""
    indentation = 0;
    validConfig.clear();
    if (config.has("#Comments")) {
        var comments = config.get("#Comments");
        // to keep indentation
        comments = comments.replaceAll(" ", "&nbsp");
        var lines = comments.split('\n');

        // show config comment on top, disabled to look cleaner
        if (false) {
            // <tt>: monospace font
            var linesWithBr = "<tt>";
            lines.forEach(function (line) {
                linesWithBr += "# " + line + "<br>";
            })
            linesWithBr += "</tt>";
            logInfo(linesWithBr);
        }
        validConfig.add("#Comments");
    }

    try {
        knowledge_Main();

        indentation = 0;
        var notConsumed = "";
        // config not covered by options
        config.forEach(function (value, key) {
            if (!validConfig.has(key)) {
                //                    const keyInQuotes = "\"" + key + "\"";
                //                    const valueInQuotes = "\"" + value + "\"";
                notConsumed += "<br>\n* " + key + " = " + value + "";
            }
        })

        var errors = "";
        if (notConsumed.length) {
            errors = "unused config settings:" + notConsumed;
        }
        document.getElementById("errors").innerHTML = errors;
 
        // left side of table
        document.getElementById("canvasSection").innerHTML = g_imCanvas;
 
        // right side of table
        document.getElementById("contentSection").innerHTML = imTxt;
 
        var stateString = "";
        config.forEach(function (value, key) {
            if (key == "#Comments") {
                var lines = value.split('\n');
                lines.forEach(function (line) {
                    stateString += "# " + line + "<br>\n";
                })
        //                console.log("[" + value + "]");
            } else {
                stateString += key + " = " + value + "<br>\n";
            }
        })
        document.getElementById("state").innerHTML = stateString;

        makeConfigButtons();

        if (typeof onPageEnd !== 'undefined')
            onPageEnd();

    } 
    catch (error) {
        console.error(error);
    }

    // Add "Copy Code" helper button 
    let blocks = document.querySelectorAll("pre:has(code)");
//    console.log("Blocks ",  blocks);
    blocks.forEach((block) => {
        // only add button if browser supports Clipboard API
        if (navigator.clipboard) {
          let button = document.createElement("button");
      
          button.innerText = copyButtonLabel;
          block.appendChild(button);
      
          button.addEventListener("click", async () => {
              await copyCode(block, button);
          });
        }
      });
          
}

// code links
// view-source:http://demofox.org/DSPIIR/IIR.html

//        function MyComboF() {
//            var checkInput = document.getElementById('myCheck').checked;
//            var comboElement = document.getElementById("MyCombo2");
//            var comboValue = comboElement.options[comboElement.selectedIndex].value;
//        }



// build HTML ---------------------------------------------------------------------------

function appendParagraph(parent, txt)
{
    var it = document.createElement("p");
    it.textContent = txt;
    parent.appendChild(it);
}

// line break
function appendBr(parent) {
    parent.appendChild(document.createElement("br"));
}

// @param checked default state of the tab e.g. true or omit this parameter
function appendTab(parent, id, text, checked)
{
    // implement tab UI using a HTML radio input to store the state
    var input = document.createElement("input");
    input.type = "radio";
    input.checked = checked;
    input.className = "tabBig";
    input.name = "tabs";
    input.id = id;
    parent.appendChild(input);

    // implement tab UI using a HTML label to get the visuals
    var label = document.createElement("label");
    // The "for" attribute of <label> must be equal to the id attribute of the related element to bind them together.
    label.setAttribute("for", id);
    label.textContent = text;
    parent.appendChild(label);

    // for a small gap between the tabs
    parent.appendChild(document.createTextNode(" "));
}

window.onload = () => {
    // style sheet
    // doing it here is too late, it will flicker with old .css
//    document.head.innerHTML += '<link rel="stylesheet" href="ConfiguratorJS.css">';

    // for addCode(), see https://github.com/atom/one-dark-syntax
    document.head.innerHTML += '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.css">';

    // tab browser title
    if (!document.title.length)
        document.title = "ConfiguratorJS"

    // set favicon (todo: fix)
    {
        // < !--fav icon -->
        var link = document.createElement('link');
        link.type = 'image/x-icon';
        link.rel = 'icon';
        // google "convert base64 to image javascript"
        link.href = "data:image/x-icon;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAAAXNSR0IB2cksfwAAAAlwSFlzAAALEwAACxMBAJqcGAAAABtQTFRFAAAAAAAAAAQGAJrpAAUHAAQGAAAAAAQGAAQGeaUT1gAAAAl0Uk5TBf/////8Ff79PEB0bgAAAGBJREFUeJxjYGBUUhRSEmBgYGAyNlI2VgAzgADIEFIBMZwUGZSNjZWUjI2NgAyjgFRlMEOVgaEEyBACKWQyVgQy1BgYkowVYVIWIMUF6RDFxk4qIO1wA+FWICxlVAQ7AwArqBKSeFU15AAAAABJRU5ErkJggg==";
        document.head.appendChild(link);
    }
    {
        var center = document.createElement("center");
        center.style = "max-width: 1100px;";

        {
            var header = document.createElement("h1");
            header.className = "mainHeader";

            var image = new Image();

            // gears.png
            // google "convert base64 to image javascript"
//            image.src = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEkAAAA5BAMAAACIfxsuAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAqUExURUdwTBwvVEVlizlScztUdSM1VFR0mFh6n4Wox3SYumWIrC9LdZm51MHa7LzRwpUAAAAHdFJOUwD+/DNwqLjiMx0tAAAEQklEQVRIx32WzW8bRRjGl9rpfYogVZZDNTQsyQrJIbSoN0NTeuCCoRVIvURpBDn0gHzI4lUPKEhhxlouAYmZlXuJEM4MvewqENrhVJBYV+sLF6iU/V94Zp3UayfpK0te7/zmeT9n144zbWtrd50X2gcNx6lTehmXV6+fwYzWz1PqOU5txJ5iM5TS9c8D2Ob6WptunkUFQRgcmUffOAVBRDPeEdEGFAQ/j+5W7W16t/7FsY7FYOu1970JzIYc9MOwwoFst9sTbj+kNNBBWOWs08C736xQS2mIwPuIvspB7ekENaux3O/3NfzqMdVpT1CLoQ41HIaSx1rlg+MMaDX8c1pbSmv+o29gC4P+SKz/nDpHvVDH4PqaWcZNksRVJRYGm0EwAtfaHlSsWtcvlUrMK6F+EOrVsskehYyCWtw2pZYxFhslDQc/le1LPV1iqp2mxhyLJWkZF5ZUSZEDrazDrk+hdXtl5cadxCWJu2h96r2YjqjZWGmp9E5q/FujUN9puS45sB472v/tiAKi1X1K00+O8661bGSos5b+fBk9eYSYVCxp+vq4gjWo2Upr+ct+qZ6CUFI9mZzhGUIWbbtkbHN8NwiUlLGSW7Q5MXLvkccaHrmIsoZz0wtkLGFbU8ehDgp9lVGUN52bgaVipXZWp4a89bvUWgiW56vOZ10Zayk7cmdqyJ2lRyyOmehFbNW5Yyi0uJTbJ87UVxHjikc6WHVahHSYlJz/cOIU77EoDtW3xjSRClnY40qc1DovBdc6fmKpJVCSCSbEdFzXhLCDC6oB6oIUEtvE11PUBmNIzE5mw6l9rLAHUmx72iHjMtRq+GwdDcOFENJykwXbEANkpR8Oiz+RyWKsYkgLJlU1smuMMc67upcXf0FrLhYZ48wmsD3GroKxfVPDovge1Kzsp5xzxNZj280KBHWMwW4g7EARY8gCpGQmWMbWl7FxZSNiQmFnrHZxDEZUQuawjyMB6xd9kANmt3Epem1Ql2zrk4RctDKMRVjjkg14D3EypTBblrK5LxlCemXwUQQ2ZwOEyPZY1pUsKv4xtvRovSFzjMEHh1ZkCZtxBP9SDItDY14p81lu3Mt4bj3CMqA8Y8gEcFYUxTfLx+V5DKl+ycEpg1PWFbZenbw4/PJ5CUlH7CYHmY0NYhk+eSREt23eLLYujam5HZTjIcQyJFDqIXCMjAn9MdWylSUPijzP8nxUk3xYpuemH1Upn5DvsmGuosM8zwexQtz/2sePPz6kL1ktt8iH6MdbWN8yyYOieFZqVeakZfaXPz0sBjRJXgPlG/JHUTy9fCVxqzNXx8NmZrHYwvLFovgPXybv4r1Rv3Xi+BGXpgm5AFd+QtzU//XUFx8hKXJwGfsbVOKa/TMoM79ii2Lmb98gZ1B1aDXtA6n8ap1BOVfIfjlIrrHK7n7j9FdyrRwk133V/rj+wn8Lddd9+cTN/wFW2554MsrpcAAAAABJRU5ErkJggg==";

            image.src = "ShaderToHuman.png";

//            image.style = "image-rendering: pixelated;";
//            image.style = "image-rendering:pixelated; background:black; transform:scale(8); transform-origin: top left; border:5px solid black;";
//            image.style = "image-rendering:pixelated; background:black; width: 188px; height: 92px; border:8px solid black;";
            image.style = "image-rendering:pixelated; background:black; width: 94px; height: 46px; border:8px solid black;";
            image.className = "gearsImage"
//            image.width = 47 * 4; image.height = 23 * 4; // not pixelated
            image.width = 47; image.height = 23;

            // Create heading element
            var heading = document.createDocumentFragment();
//            heading.textContent = "\nConfiguratorJS";
//            heading.textContent = "\n" + document.title;

            const viewportWidth = window.innerWidth;

            // Append image and heading to the header
            header.appendChild(image);
            header.appendChild(heading);

            // Append the header to the body
            center.appendChild(header);

/*            appendParagraph(center, "ConfiguratorJS Version 0.77 6/18/2025 by MMittring@EA.com");
            appendParagraph(center, "SEED internal tool");

            var inputloadConfigAsTxt = document.createElement("input");
            inputloadConfigAsTxt.id = "loadConfigAsTxt";
            inputloadConfigAsTxt.name = "Load Configurator data as text";
            inputloadConfigAsTxt.accept = ".txt, .kb, .config";
            center.appendChild(inputloadConfigAsTxt);

            appendBr(document.body);
*/
            appendBr(document.body);
        }

        document.body.appendChild(center);
    }

//    appendBr(document.body);

    {
        var el = document.createElement("div");
        el.className = "StateButtons";
        el.textContent = "Configs: ";
        document.body.appendChild(el);
    }

//    appendBr(document.body);
//    appendBr(document.body);

    appendTab(document.body, "tab1", "Content", true);
//for developer    appendTab(document.body, "tab2", "Key/Value pairs");
//for developer    appendTab(document.body, "tab3", "Errors");

    {
        var el = document.createElement("div");
        el.className = "tab content1";

        var elTable = document.createElement("div");
        elTable.className = "flex-container";
        el.appendChild(elTable);

        var elLeft = document.createElement("div");
        elLeft.className = "left-section";
       
        var leftP = document.createElement("p");
        leftP.style = "line-height: 2; border-color: #888888; padding: 8px; margin: 0px;";
        leftP.id = "canvasSection"; // we will append the canvas there

        var elRight = document.createElement("div");
        elRight.className = "right-section";
//        elRight.style = "vertical-align: top;";
        elTable.appendChild(elRight);
        elTable.appendChild(leftP);
        
        var it = document.createElement("p");
        it.style = "line-height: 2; border-color: #888888; padding: 8px; margin: 0px;";
        it.id = "contentSection"; // we will append the content there
        elRight.appendChild(it);

        document.body.appendChild(el);
    }
    {
        var el = document.createElement("div");
        el.className = "tab content2";

        var it = document.createElement("p");
        it.className = "readOnlyTextBox";
        it.id = "state";
        el.appendChild(it);

        document.body.appendChild(el);
    }
    {
        var el = document.createElement("div");
        el.className = "tab content3";

        var it = document.createElement("p");
        it.className = "readOnlyTextBox";
        it.id = "errors";
        el.appendChild(it);

        document.body.appendChild(el);
    }

    // ---------------------------

    document.getElementById("loadConfigAsTxt")?.addEventListener("change", importLocalFile);
    resetUI();
    extractDataFromHTML();

    // optional callback for first time after page is there, can call onConfigButton()
    if (Configurator.getAndSetFirst()) {
        if (typeof onFirstTime !== 'undefined')
            onFirstTime();
    }
}
// glm-js backend for Matrix Configurator
//
// https://humbletim.github.io/glm-js

// see setup2DCanvas()
var g_CanvasContext;

// @param type "2D" or "3D"
// used by genCanvas()
function setup2DCanvas(type, name) {
    if (g_CanvasContext === undefined) {
        var canvas = document.getElementById(name);
        var ctx = canvas.getContext("2d");

        g_CanvasContext = {
            canvas: canvas,
            ctx: ctx,
            mode: type,                                 // "2D": 2D viewport, "3D": 3D viewport
            viewPan: glm.vec2(0.0, 0.0),                // for 2D viewports
            cameraPos: glm.vec3(0.0, 3, -10.0),        // for 3D viewports, go 10m back and a bit up
            cameraAngles: glm.vec3(0.0, 0.0, 0.0),      // for 3D viewports
        };

        canvas.addEventListener('mousemove', mouseInput);
        canvas.addEventListener('mousedown', mouseInput);
        canvas.addEventListener('mouseup', mouseInput);
        canvas.addEventListener('keydown', keyDown);
        canvas.addEventListener('keyup', keyUp);
    }
    // reset canvas (clear the canvas for redrawing)
    g_CanvasContext.canvas.width = g_CanvasContext.canvas.width;
}

var g_CanvasGLContext;

// uses g_CanvasGLContext 
function updateGLCanvas() {

    var gl = g_CanvasGLContext.gl;
    var program = g_CanvasGLContext.program;
    var canvas = g_CanvasGLContext.canvas;

    var viewFromWorld = computeCameraMatrix();

    const aspectRatio = canvas.width / canvas.height;
    var clipFromView = perspectiveFovInfInvZRh(0.4 * 3.14, aspectRatio, 0.01); //glm.perspective(glm.radians(45.0), 4.0 / 3.0, 0.1, 100.0);

    var clipFromWorld = clipFromView['*'](viewFromWorld);

    {
        const location = gl.getUniformLocation(program, "u_clipFromWorld");
        gl.uniformMatrix4fv(location, false, clipFromWorld.elements);
    }
    {
        var worldFromClip = glm.inverse(clipFromWorld);
        const location = gl.getUniformLocation(program, "u_worldFromClip");
        gl.uniformMatrix4fv(location, false, worldFromClip.elements);
    }
    {
        var worldFromView = glm.inverse(viewFromWorld);
        const location = gl.getUniformLocation(program, "u_worldFromView");
        gl.uniformMatrix4fv(location, false, worldFromView.elements);
    }
    {
        const location = gl.getUniformLocation(program, "u_windowSize");
        gl.uniform4f(location, canvas.width, canvas.height, 1.0 / canvas.width, 1.0 / canvas.height);
    }
    // Shadertoy
    {
        {
            // In Shadertoy this a 3 component vector
            const location = gl.getUniformLocation(program, "iResolution");
            gl.uniform3f(location, canvas.width, canvas.height, 1.0);
        }
        {
            var absTime = getTimeSliderState();

            const location = gl.getUniformLocation(program, "iTime");
            gl.uniform1f(location, absTime);
        }
        {
            var state = getIMouseState();

            const location = gl.getUniformLocation(program, "iMouse");
            
            gl.uniform4f(location, state.x, state.y, state.z, state.w);
        }
    }
    // Note: Addding more values here also requires also requires code near "uniform vec4 iMouse;".

    gl.drawArrays(gl.TRIANGLES, 0, 6);
}

// @param title string
// @param str string
// @return string
function printWithLineNumbers(title, str)
{
    console.log(`${title} = `);
    const lines = str.replace(/\r/g, '').split('\n');
    lines.forEach((line, index) => {
        console.log(`${index + 1}: ${line}`);
    });
    console.log(``);
}

// @return glm.vec4
function getIMouseState()
{
    const downSign = g_CanvasGLContext.down ? 1 : -1;
    const clickedSign = g_CanvasGLContext.clicked ? 1 : -1;
    return glm.vec4(g_CanvasGLContext.downXY, g_CanvasGLContext.clickXY.x * downSign, g_CanvasGLContext.clickXY.y * clickedSign);
}

// setup g_CanvasGLContext, calls getBackendCode("GLSL") to generate the code for the WebGL canvas
function setupGLCanvas(type, name) {

    if (g_CanvasGLContext === undefined) {
        var canvas = document.getElementById(name);

        canvas.addEventListener('mousemove', mouseInput);
        canvas.addEventListener('mousedown', mouseInput);
        canvas.addEventListener('mouseup', mouseInput);
        canvas.addEventListener('keydown', keyDown);
        canvas.addEventListener('keyup', keyUp);

        const gl = canvas.getContext("webgl2");
        gl.clearColor(0.1, 0.2, 0.3, 1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT | gl.COLOR_BUFFER_BIT);
        
        const posData = [
            // first triangle
            1, 1, 0.0,  // top right
            1, -1, 0.0,  // bottom right
            -1, 1, 0.0,  // top left 
            // second triangle
            1, -1, 0.0,  // bottom right
            -1, -1, 0.0,  // bottom left
            -1, 1, 0.0   // top left
        ];

        const shaderConstants =
        `
        uniform vec4 iMouse;
        uniform vec3 iResolution;
        uniform float iTime;
        uniform mat4 u_clipFromWorld;
        uniform mat4 u_worldFromClip;
        uniform mat4 u_worldFromView;
        uniform vec2 u_WindowSize;
        `;

        // next line should start at 100 making error messages easier to interpret
        const vsCode = `#version 300 es
        precision highp float;
        ${shaderConstants}
        in vec3 position;

        vec3 homAway(vec4 p) { return p.xyz / p.w; }

        void main() {
            vec4 csPosHom = u_clipFromWorld * vec4(position.x, position.y, position.z, 1.0);
            vec3 csPos = homAway(csPosHom);

            // world space quad at xy plane
    //        gl_Position = csPosHom;

            // full screen quad, for ray tracing 
            gl_Position = vec4(position.xyz, 1.0);
        }
        `;


















        // like GLSL but includes are getting expanded
        var GLSLCode = getBackendCode("WebGL");
        console.assert(GLSLCode != null);






        // Shadertoy
        const fsCode = `#version 300 es
        precision highp float;
        ${shaderConstants}
        out vec4 g_color;
        ${GLSLCode}
        
        void main()
        {
            mainImage(g_color, gl_FragCoord.xy);
            g_color.a = 1.0f;
        }
        `;

        const vs = gl.createShader(gl.VERTEX_SHADER);

        gl.shaderSource(vs, vsCode);

        gl.compileShader(vs);

        if (!gl.getShaderParameter(vs, gl.COMPILE_STATUS)) {
            console.error("Vertex Shader " + gl.getShaderInfoLog(vs));
        }


        // process fragment shader
        const fs = gl.createShader(gl.FRAGMENT_SHADER);

        gl.shaderSource(fs, fsCode);

        gl.compileShader(fs);

        if (!gl.getShaderParameter(fs, gl.COMPILE_STATUS)) {
            console.error("Fragment Shader " + gl.getShaderInfoLog(fs));
            printWithLineNumbers("fsCode",fsCode);
//            console.log("\n\nfsCode='" + fsCode + "'\n\n");
        }

        const program = gl.createProgram();

        // Attach pre-existing shaders
        gl.attachShader(program, vs);
        gl.attachShader(program, fs);

        gl.linkProgram(program);

        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            const info = gl.getProgramInfoLog(program);
            throw `Could not compile WebGL program. \n\n"${info}"`;
        }

        const buffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(posData), gl.STATIC_DRAW);

        gl.bindBuffer(gl.ARRAY_BUFFER, null);

        gl.useProgram(program);

        // get index that holds the triangle position information
        const position = gl.getAttribLocation(program, "position");

        gl.enableVertexAttribArray(position);

        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

        gl.vertexAttribPointer(position, 3, gl.FLOAT, gl.FALSE, gl.FALSE, 0, 0);

        g_CanvasGLContext = {
            gl: gl,
            program: program,
            canvas: canvas,
            down: false,
            clicked: false,
            downXY: glm.vec2(-1, -1),
            clickXY: glm.vec2(-1, -1),
        };
    }

    updateGLCanvas();
}

// @param delta glm.vec2(horizontal, vertical)
function rotateCamera(delta) {
    let yborder = 0.00001;

    g_CanvasContext.cameraAngles.x += delta.x;
    g_CanvasContext.cameraAngles.y += delta.y;

    // wrap in 0..2*PI to minimize floating point errors
    g_CanvasContext.cameraAngles.x = glm.fract(g_CanvasContext.cameraAngles.x / (2 * Math.PI)) * (2 * Math.PI);

    // clamp top
    g_CanvasContext.cameraAngles.y = glm.max(g_CanvasContext.cameraAngles.y, -Math.PI * 0.5 + yborder);
    // clamp bottom
    g_CanvasContext.cameraAngles.y = glm.min(g_CanvasContext.cameraAngles.y, Math.PI * 0.5 - yborder);
}

// normalized forward vector 
// @return glm.vec3
function computeCameraForward() {
    var sx = Math.sin(g_CanvasContext.cameraAngles.x);
    var cx = Math.cos(g_CanvasContext.cameraAngles.x);
    var sy = Math.sin(g_CanvasContext.cameraAngles.y);
    var cy = Math.cos(g_CanvasContext.cameraAngles.y);

    return glm.vec3(sx * cy, sy, cx * cy);
}

// @return glm.vec3
function computeCameraRight() {
    return glm.cross(getCameraUp(), computeCameraForward());
}

// @return glm.vec3
function getCameraUp() {
    return glm.vec3(0.0, 1.0, 0.0);
}

// aka viewFromWorld
// @return glm.mat4
function computeCameraMatrix() {
    console.assert(g_CanvasContext != null);

    // Is this LR or RH?
    return glm.lookAt(
        g_CanvasContext.cameraPos,
        g_CanvasContext.cameraPos['+'](computeCameraForward()), // g_CanvasContext.cameraPos + computeCameraForward(),
        getCameraUp(),
    );
}

// from Halcyon
// @return glm.mat4
function perspectiveFovInfInvZRh(fov, aspectRatio, zNear) {
    const rad = fov;
    const h = Math.cos(0.5 * rad) / Math.sin(0.5 * rad);
    const w = h / aspectRatio;

    var result = glm.mat4(0.0);
    result[0][0] = w;
    result[1][1] = h;
    result[2][3] = -1.0;

    result[2][2] = 0.0;
    result[3][2] = zNear;

    return result;
}

const keysPressed = new Set();
function keyDown(event) {
    keysPressed.add(event.key);
}
function keyUp(event) {
    keysPressed.delete(event.key);
}


// called with requestAnimationFrame()
let g_keyUpdateTime;
function keyUpdate(timestamp) {
    requestAnimationFrame(keyUpdate);

    if (g_CanvasContext === undefined)
        return;

    if (g_keyUpdateTime === undefined)
        start = g_keyUpdateTime;

    // todo
    const frameTime = Math.min(timestamp - g_keyUpdateTime, 0.1);

    const movementSpeed = 0.2;
    let forward = computeCameraForward()['*'](movementSpeed);
    let right = computeCameraRight()['*'](movementSpeed);

    var update = false;

    if (keysPressed.has('w') || keysPressed.has('W')) {
        g_CanvasContext.cameraPos = g_CanvasContext.cameraPos['+'](forward);
        update = true;
    }
    if (keysPressed.has('a') || keysPressed.has('A')) {
        // todo: why is is backwards?
        g_CanvasContext.cameraPos = g_CanvasContext.cameraPos['+'](right);
        update = true;
    }

    if (keysPressed.has('s') || keysPressed.has('S')) {
        g_CanvasContext.cameraPos = g_CanvasContext.cameraPos['-'](forward);
        update = true;
    }

    if (keysPressed.has('d') || keysPressed.has('D')) {
        // todo: why is is backwards?
        g_CanvasContext.cameraPos = g_CanvasContext.cameraPos['-'](right);
        update = true;
    }

    // redraw scene
    if (update)
        eval(g_imJSCode); // todo: mouse movement + key is double apply
}
requestAnimationFrame(keyUpdate);

function mouseInput(event) {
    //    console.log(event);

    const buttons = event.buttons;

    let pos;

    if (g_CanvasContext.mode === "2D") {
        const rect = g_CanvasContext.canvas.getBoundingClientRect();
        pos = glm.vec2(event.clientX - rect.left, event.clientY - rect.top);
        // left button
        if (buttons & 1) {
            // 2d pan
            g_CanvasContext.viewPan.x += event.movementX;
            g_CanvasContext.viewPan.y += event.movementY;
        }
    }
    else {
        const rect = g_CanvasGLContext.canvas.getBoundingClientRect();
        pos = glm.vec2(event.clientX - rect.left, event.clientY - rect.top);
        const oldDown = g_CanvasGLContext.down;
        g_CanvasGLContext.down = (buttons & 1) != 0;
        g_CanvasGLContext.clicked = g_CanvasGLContext.down && !oldDown;

        // left button
        if (buttons & 1) {
            // 3D rotate
            const scale = 0.004;
            rotateCamera(glm.vec2(-event.movementX * scale, -event.movementY * scale));
            g_CanvasGLContext.downXY = pos;
        }

        if(g_CanvasGLContext.clicked)
            g_CanvasGLContext.clickXY = pos;
    }

    // redraw scene
    eval(g_imJSCode);
}


// Canvas helper functions

// used by loadAllFiles()
// @param fileName e.g. "test.hlsl"
async function loadHLSLFile(fileName) {
    try {
        const response = await fetch(fileName);
        if (!response.ok) throw new Error(`Failed to fetch ${fileName}`);
        const code = await response.text();
        return code;
    } catch (err) {
        console.error(err);
    }
}

// @param files = strings array
function appendfile(files, name) {
    files.push(name + ".glsl");
    files.push(name + ".hlsl");
}

// @param files = strings array
function appendfileRange(files, name, endIndex) {
    for(let i = 0; i <= endIndex; ++i)
        appendfile(files, name + "_" + i);
}

async function loadAllFiles() {

    // important: use '/', not '\\'
    const files = [
//        "docs/intro_0.hlsl", 
//        "docs/intro_0.glsl",
//        "docs/gather_docs_1.hlsl",
//        "docs/gather_docs_1.glsl",
//       "include/s2h.hlsl",
//        "include/s2h.glsl"
    ];
    // GitHub does not allow 'listfiles' so we have to do this manually
    // or we could generate the list with transpileToGLSL.bat .
    appendfileRange(files, "docs/2d_docs", 10);
    appendfileRange(files, "docs/3d_docs", 5);
    appendfileRange(files, "docs/gather_docs", 6);
    appendfileRange(files, "docs/intro", 0);
    appendfileRange(files, "docs/scatter_docs", 7);
    appendfileRange(files, "docs/ui_docs", 5);
    appendfile(files, "include/s2h");
    appendfile(files, "include/s2h_3d");
    appendfile(files, "include/s2h_scatter");

    // todo: if this is too slow, we can optimize it
    for (let el of files) {
        const code = await loadHLSLFile(el);  // wait for fetch to complete
        g_HLSLInputCode.set(el.replace("/", "\\"), code); // store the string, not a promise
    }

    /*
    const url = '/listfiles';
    paths = []
    return fetch(url)
        .then(response => {
            if(!response.ok){
                throw new Error('Unable to get list of files');
            }
            return response.json();
        })
        .then(files => {
            console.log("Loading files");
            paths = files;
            const loads = files.map(path=>loadHLSLFile(path));
            return Promise.all(loads);
        })
        .then(shaders => {
            shaders.forEach((shaderCode, index) => {
                const shaderPath = paths[index]; 
                g_HLSLInputCode.set(shaderPath, shaderCode);
            });
        })
        .catch(error => {
            console.error(error);
        });
        */
}

// call once in beginning to load multiple hlsl files so they can be accessed with code like this:
// var lines = g_HLSLInputCode.get("MixColor.hlsl");
function loadMultipleHLSLFiles(shaderPaths) {
    loadAllFiles()
}
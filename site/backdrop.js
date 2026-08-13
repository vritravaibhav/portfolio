/**
 * Animated WebGL backdrop: a domain-warped fBm field drifting behind the page.
 *
 * Raw WebGL, no library. The CSS gradient on `.backdrop` stays underneath as
 * the fallback, so if the context fails, the shader is unsupported, or the
 * visitor asked for reduced motion, the page keeps the static gradient it had
 * before and nothing is lost.
 *
 * Cost control, because this runs behind every scroll:
 *   - renders at a fraction of device resolution (it is all low-frequency
 *     colour, so the upscale is invisible) and caps DPR
 *   - throttles to ~30fps rather than chasing the display refresh rate
 *   - stops entirely when the tab is hidden or the canvas scrolls out of view
 *   - draws a single frame and stops under prefers-reduced-motion
 */

const VERTEX_SHADER = `
attribute vec2 a_position;
void main() {
  gl_Position = vec4(a_position, 0.0, 1.0);
}`;

/**
 * Two rounds of domain warping (Iñigo Quílez's pattern): fbm feeds a second
 * fbm, whose output offsets a third. That is what produces the curdled,
 * flowing look — a single fbm alone reads as flat static.
 */
const FRAGMENT_SHADER = `
precision highp float;

uniform vec2  u_resolution;
uniform float u_time;
uniform vec2  u_pointer;

const vec3 DEEP  = vec3(0.027, 0.039, 0.071);
const vec3 MID   = vec3(0.063, 0.102, 0.180);
const vec3 CYAN  = vec3(0.059, 0.941, 0.988);
const vec3 BLUE  = vec3(0.000, 0.361, 1.000);

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);          // smoothstep, cheaper inline
  return mix(mix(hash(i),                hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 5; i++) {
    value += amplitude * noise(p);
    p *= 2.02;                                // non-integer, to avoid banding
    amplitude *= 0.5;
  }
  return value;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  // Correct for aspect so the field does not stretch on wide viewports.
  vec2 p = uv * vec2(u_resolution.x / u_resolution.y, 1.0) * 2.2;

  float t = u_time * 0.045;

  vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, 1.3)));
  vec2 r = vec2(fbm(p + 3.4 * q + vec2(1.7, 9.2) + 0.14 * t),
                fbm(p + 3.4 * q + vec2(8.3, 2.8) + 0.11 * t));
  float f = fbm(p + 3.2 * r);

  // Base: deep navy lifting toward the top of the page.
  vec3 color = mix(DEEP, MID, smoothstep(0.0, 1.0, uv.y * 0.85 + 0.1));

  // Currents. Every intensity below is deliberately low: this sits behind body
  // copy, and the moment the backdrop competes with the text it has failed,
  // however good it looks in isolation.
  float current = smoothstep(0.44, 0.96, f);
  color = mix(color, BLUE * 0.55, current * 0.30);
  color += CYAN * pow(current, 3.0) * 0.13;

  // Filaments: the ridges of the warp field, which read as fine structure.
  float filament = 1.0 - abs(r.x - r.y) * 3.4;
  color += CYAN * pow(max(filament, 0.0), 7.0) * 0.06;

  // The bloom the static design already had, near the top-left.
  float bloom = 1.0 - smoothstep(0.0, 0.95, distance(uv, vec2(0.22, 0.92)));
  color += CYAN * pow(bloom, 2.4) * 0.10;

  // Pointer warmth: present enough to notice on move, never a spotlight.
  float glow = 1.0 - smoothstep(0.0, 0.42, distance(uv, u_pointer));
  color += CYAN * pow(glow, 2.6) * 0.06;

  // Vignette, so the text columns keep their contrast at the edges.
  color *= 1.0 - 0.40 * pow(distance(uv, vec2(0.5)) * 1.25, 2.2);

  // Ordered dither: 5-octave fbm in 8-bit output bands badly without it.
  float dither = (hash(gl_FragCoord.xy) - 0.5) / 255.0;
  gl_FragColor = vec4(color + dither, 1.0);
}`;

function compile(gl, type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);

  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    const log = gl.getShaderInfoLog(shader);
    gl.deleteShader(shader);
    throw new Error(`shader compile failed: ${log}`);
  }
  return shader;
}

function createProgram(gl) {
  const program = gl.createProgram();
  const vertex = compile(gl, gl.VERTEX_SHADER, VERTEX_SHADER);
  const fragment = compile(gl, gl.FRAGMENT_SHADER, FRAGMENT_SHADER);

  gl.attachShader(program, vertex);
  gl.attachShader(program, fragment);
  gl.linkProgram(program);

  // Attached shaders are reference-counted; the program keeps them alive.
  gl.deleteShader(vertex);
  gl.deleteShader(fragment);

  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    const log = gl.getProgramInfoLog(program);
    gl.deleteProgram(program);
    throw new Error(`program link failed: ${log}`);
  }
  return program;
}

export function startBackdrop(canvas) {
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

  const gl = canvas.getContext('webgl', {
    alpha: false,
    antialias: false,
    depth: false,
    stencil: false,
    powerPreference: 'low-power',
    failIfMajorPerformanceCaveat: true,   // decline software rasterisers
  });
  if (!gl) return null;

  let program;
  try {
    program = createProgram(gl);
  } catch (error) {
    console.warn('[backdrop]', error.message);
    return null;
  }

  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  // One full-screen triangle rather than two: no diagonal seam, one fewer vertex.
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);

  const position = gl.getAttribLocation(program, 'a_position');
  gl.enableVertexAttribArray(position);
  gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
  gl.useProgram(program);

  const uniforms = {
    resolution: gl.getUniformLocation(program, 'u_resolution'),
    time: gl.getUniformLocation(program, 'u_time'),
    pointer: gl.getUniformLocation(program, 'u_pointer'),
  };

  // The field is all low-frequency colour, so rendering well under device
  // resolution costs nothing visually and saves most of the fill rate.
  const RENDER_SCALE = 0.5;
  const MAX_DPR = 1.5;

  function resize() {
    const dpr = Math.min(devicePixelRatio || 1, MAX_DPR) * RENDER_SCALE;
    const width = Math.max(1, Math.round(canvas.clientWidth * dpr));
    const height = Math.max(1, Math.round(canvas.clientHeight * dpr));

    if (canvas.width === width && canvas.height === height) return;

    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);
    gl.uniform2f(uniforms.resolution, width, height);
  }

  // Pointer is smoothed toward the target so the glow trails rather than snaps.
  const pointer = { x: 0.22, y: 0.85, targetX: 0.22, targetY: 0.85 };

  addEventListener('pointermove', (event) => {
    pointer.targetX = event.clientX / innerWidth;
    pointer.targetY = 1 - event.clientY / innerHeight;   // GL origin is bottom-left
  }, { passive: true });

  function render(seconds) {
    pointer.x += (pointer.targetX - pointer.x) * 0.045;
    pointer.y += (pointer.targetY - pointer.y) * 0.045;

    gl.uniform1f(uniforms.time, seconds);
    gl.uniform2f(uniforms.pointer, pointer.x, pointer.y);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
  }

  resize();
  addEventListener('resize', resize, { passive: true });

  if (reduceMotion) {
    render(12);                     // one frame, mid-drift, then done
    canvas.classList.add('ready');
    return { stop() {} };
  }

  const FRAME_MS = 1000 / 30;       // 30fps is plenty for something this slow
  let frame = null;
  let last = 0;
  let visible = true;

  function loop(now) {
    frame = requestAnimationFrame(loop);
    if (now - last < FRAME_MS) return;
    last = now;
    render(now / 1000);
  }

  function start() {
    if (frame === null && visible) {
      last = 0;
      frame = requestAnimationFrame(loop);
    }
  }

  function stop() {
    if (frame !== null) {
      cancelAnimationFrame(frame);
      frame = null;
    }
  }

  document.addEventListener('visibilitychange', () => {
    visible = !document.hidden;
    visible ? start() : stop();
  });

  // Nothing to animate while the canvas is scrolled out of view.
  new IntersectionObserver(([entry]) => {
    visible = entry.isIntersecting && !document.hidden;
    visible ? start() : stop();
  }, { threshold: 0 }).observe(canvas);

  start();
  canvas.classList.add('ready');
  return { stop };
}

/* EFSM view: MMST.efsm.render(host, machines), machines from /api/efsm.
   Labels:  "6[Stream] ▷1:"    state 6, binds rec Stream, mixed choice 1 starts here
            "7[] 1:"           in mixed choice 1 ("2[] 0:" outside)
            "9[] 1: Stream:"   continue Stream
            "A?a1()/A!*TOa()"  event/action: 𝜏 internal, ? message arrival, ! send, ε empty,
                               * switch to the right side of the mixed choice.
   Shown as in the paper's Figure 2, "B?a4()/ε" as "B?a4()" and "B?TOa()/ε*" as "B?*TOa()",
   but τ in gen_statem's word: "𝜏_a1/B!a1()" as "internal / B!a1()". The subscript always
   repeats the message sent. */
(function(){
  "use strict";

  var MMST = window.MMST = window.MMST || {};
  var NS = "http://www.w3.org/2000/svg";
  var R = 18, DY = 112, PAD = 40;
  var NODE = /^(\S+?)\[([^\]]*)\]\s*(▷)?(\d+):\s*(?:([A-Za-z_][A-Za-z0-9_]*):)?\s*$/;
  var REDUCED = !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  var SIDE = { lhs: "left", rhs: "right", none: "outside", jump: "continue" };
  var gen = 0;                                                  // per drawing: stale runs stop

  function svg(tag, attrs, parent){
    var e = document.createElementNS(NS, tag);
    if (attrs) for (var k in attrs) if (attrs[k] != null) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  }
  function tag(name, cls, text, parent){
    var e = document.createElement(name);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  }
  function f(v){ return Math.round(v * 10) / 10; }
  function labelOf(e){ return e.jump || !e.action ? e.event : e.event + " / " + e.action; }

  // A label in the local types' colours: roles bold, ? ! * as operators, messages in the
  // colour of their side, payloads and keywords quieter. Kinds: role op lab pay kw var dot.
  // A message is on the right if marked *; one in the same switch without * is on the left.
  var MSG = /^([A-Za-z_][A-Za-z0-9_]*)([?!]\*?)([A-Za-z0-9_]+)(\(.*\))?$/;
  function parts(s, e){
    var m = MSG.exec(s), c;
    if (m) return [["role", m[1]], ["op", m[2]], ["lab", m[3], m[2].length > 1 ? "rhs" : e.toRight ? "lhs" : e.side],
                   ["pay", m[4] || ""]];
    if ((c = /^continue (\S+)$/.exec(s))) return [["kw", "continue "], ["var", c[1]]];
    if (s === "internal") return [["kw", s]];
    return [["", s]];
  }
  function whole(e){ return e.jump || !e.action ? parts(e.event, e) : parts(e.event, e).concat(SLASH, parts(e.action, e)); }
  var SLASH = [["", " "], ["dot", "/"], ["", " "]];
  function tspans(text, list){                                  // SVG
    list.forEach(function(p){
      if (p[1]) svg("tspan", p[0] ? { "class": "t-" + p[0] + (p[2] ? " " + p[2] : "") } : null, text).textContent = p[1];
    });
  }
  function spans(el, list){                                     // HTML, with the local types' classes
    list.forEach(function(p){
      if (!p[1]) return;
      if (p[0] === "role") tag("b", "lt-role", p[1], el);
      else if (p[0] === "var") tag("i", "lt-var", p[1], el);
      else if (p[0] === "lab") tag("span", "lt-lab" + (p[2] === "lhs" ? " lt-l" : p[2] === "rhs" ? " lt-r" : ""), p[1], el);
      else tag("span", p[0] ? "lt-" + p[0] : null, p[1], el);
    });
  }

  // The local type's actions an edge takes: "role ! label" or "role ? label", in which mixed
  // choice and on which side, as MMST.localType marks them.
  function acts(e){
    var out = [], mc = String(e.from.mc || 0);
    [e.event, e.action].forEach(function(s){
      var m = MSG.exec(s || "");
      if (!m) return;
      var side = m[2].length > 1 ? "rhs" : e.toRight ? "lhs" : e.side;
      out.push({ key: m[1] + " " + m[2][0] + " " + m[3], mc: mc, side: side === "lhs" ? "l" : side === "rhs" ? "r" : "" });
    });
    return out;
  }

  // An edge's code in the generated files: its clause of the state's function in
  // gen_<role>.erl, the callback's in <role>.erl, and the send, if it sends.
  function reEsc(s){ return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); }
  function clause(text, re){                                    // from its head to the next line at column 0
    var lines = text.split("\n");
    for (var i = 0; i < lines.length; i++) if (re.test(lines[i])) {
      var j = i + 1;
      while (j < lines.length && !/^\S/.test(lines[j])) j++;
      while (j > i + 1 && !lines[j - 1].trim()) j--;
      return { text: lines.slice(i, j).join("\n"), line: i + 1, to: j };
    }
    return null;
  }
  function clauses(files, role, e){
    var lower = String(role).toLowerCase(), st = "s" + e.from.id, out = [];
    function file(n){ return files.filter(function(f){ return f.name.toLowerCase() === n; })[0]; }
    var gen = file("gen_" + lower + ".erl"), cb = file(lower + ".erl");
    var ev = MSG.exec(e.event || ""), ac = MSG.exec(e.action || "");
    var head = ev ? new RegExp("^" + st + "\\(cast,\\s*\\{[^{]*\\{'?" + reEsc(ev[3]) + "'?[,}]")
             : ac ? new RegExp("^" + st + "\\(internal,\\s*\\{'?" + reEsc(ac[3]) + "'?[,}]") : null;
    function add(f, re, fn, note){
      var c = f && re && clause(f.content, re);
      if (c) out.push({ file: f.name, fn: fn, note: note, text: c.text, line: c.line, to: c.to });
    }
    add(gen, head, st + "/3", "state " + e.from.id + ", generated");
    add(cb, head, st + "/3", "your callback");
    if (ac) add(gen, new RegExp("^send_" + st + "_" + reEsc(ac[3]) + "\\("), "send_" + st + "_" + ac[3] + "/2", "the send, generated");
    return out;
  }

  /* model */
  function model(m){
    var nodes = [], byId = {};
    (m.nodes || []).forEach(function(raw){
      var x = NODE.exec(raw.label || "") || [];
      var n = { id: raw.id, label: raw.label || "", rec: (x[2] || "").split(/[\s,]+/).filter(Boolean),
                entry: !!x[3], mc: x[4] ? +x[4] : 0, cont: x[5] || "", out: [], inn: [] };
      nodes.push(n); byId[n.id] = n;
    });
    var edges = [];
    (m.edges || []).forEach(function(raw){
      var a = byId[raw.from], b = byId[raw.to];
      if (!a || !b) return;
      var label = raw.label || "", cut = label.indexOf("/");
      var ev = cut < 0 ? label : label.slice(0, cut), act = cut < 0 ? "" : label.slice(cut + 1);
      var toRight = act.indexOf("*") >= 0;
      if (act === "ε" || act === "ε*") {                       // "B?m" is short for "B?m / ε"
        if (toRight) ev = ev.replace("?", "?*");
        act = "";
      }
      if (/^𝜏/.test(ev)) ev = "internal";                        // τ in the paper
      var e = { from: a, to: b, label: label, event: ev, action: act, toRight: toRight };
      edges.push(e); a.out.push(e); b.inn.push(e);
    });
    var start = nodes[0] || null;                               // initial state first

    // continue X: a dashed jump to the state binding X (the tool prints no edge).
    var binder = {}, jumps = [];
    nodes.forEach(function(n){ n.rec.forEach(function(v){ binder[v] = n; }); });
    nodes.forEach(function(n){
      if (n.cont && binder[n.cont]) {
        n.jump = { from: n, to: binder[n.cont], jump: true, event: "continue " + n.cont, action: "", side: "jump" };
        jumps.push(n.jump);
      }
    });

    // DFS topological order, then longest-path layers.
    var seen = {}, post = [], pre = 0;
    function dfs(n){
      if (seen[n.id]) return;
      seen[n.id] = true; n.pre = pre++;
      n.out.forEach(function(e){ dfs(e.to); });
      post.push(n);
    }
    if (start) dfs(start);
    nodes.forEach(dfs);
    var topo = post.reverse(), rank = {};
    topo.forEach(function(n, i){ rank[n.id] = i; n.layer = 0; });
    topo.forEach(function(n){
      n.out.forEach(function(e){
        if (rank[e.to.id] > rank[n.id]) e.to.layer = Math.max(e.to.layer, n.layer + 1);
      });
    });

    // Right: switches (*) and all steps after them. Left: other mixed-choice steps.
    topo.forEach(function(n){
      n.rhs = n.mc > 0 && n.inn.length > 0 && n.inn.every(function(e){ return e.side === "rhs"; });
      n.out.forEach(function(e){ e.side = (e.toRight || n.rhs) ? "rhs" : (n.mc > 0 ? "lhs" : "none"); });
    });
    nodes.forEach(function(n){ n.end = !n.out.length && !n.jump; });
    return { nodes: nodes, edges: edges, jumps: jumps, start: start };
  }

  /* layout */
  function layout(g){
    var widest = 0, layers = [];
    g.edges.forEach(function(e){ widest = Math.max(widest, e.lw); });
    var DX = Math.max(150, Math.min(230, widest + 40));
    g.nodes.forEach(function(n){ (layers[n.layer] = layers[n.layer] || []).push(n); });
    for (var i = 0; i < layers.length; i++) layers[i] = layers[i] || [];
    layers.forEach(function(l){
      l.sort(function(a, b){ return a.pre - b.pre; });
      l.forEach(function(n, j){ n.idx = j; });
    });
    for (var sweep = 0; sweep < 4; sweep++) {                   // barycentre ordering
      for (var L = 1; L < layers.length; L++) {
        layers[L].forEach(function(n){
          var ps = n.inn.map(function(e){ return e.from; }).filter(function(p){ return p.layer < n.layer; });
          n.bc = ps.length ? ps.reduce(function(t, p){ return t + p.idx; }, 0) / ps.length : n.idx;
        });
        layers[L].sort(function(a, b){ return (a.bc - b.bc) || (a.pre - b.pre); });
        layers[L].forEach(function(n, j){ n.idx = j; });
      }
    }
    var tall = 1;
    layers.forEach(function(l){ tall = Math.max(tall, l.length); });
    layers.forEach(function(l, L){
      var off = (tall - l.length) * DY / 2;
      l.forEach(function(n, j){ n.x = PAD + 70 + L * DX; n.y = PAD + 34 + off + j * DY; });
    });
  }

  function toward(n, x, y, r){
    var dx = x - n.x, dy = y - n.y, l = Math.sqrt(dx * dx + dy * dy) || 1;
    return { x: n.x + dx / l * r, y: n.y + dy / l * r };
  }
  function curve(e, a, b, bow){
    var dx = b.x - a.x, dy = b.y - a.y, len = Math.sqrt(dx * dx + dy * dy) || 1;
    var nx = -dy / len, ny = dx / len;
    var cx = (a.x + b.x) / 2 + nx * bow * 2, cy = (a.y + b.y) / 2 + ny * bow * 2;
    var s = toward(a, cx, cy, R + 1), t = toward(b, cx, cy, R + 4);
    e.d = "M" + f(s.x) + "," + f(s.y) + " Q" + f(cx) + "," + f(cy) + " " + f(t.x) + "," + f(t.y);
    e.lx = 0.25 * s.x + 0.5 * cx + 0.25 * t.x;
    e.ly = 0.25 * s.y + 0.5 * cy + 0.25 * t.y;
  }
  function loop(e, n){
    var x = n.x, y = n.y - R;
    e.d = "M" + f(x - 8) + "," + f(y + 2) + " C" + f(x - 36) + "," + f(y - 46) + " " +
          f(x + 36) + "," + f(y - 46) + " " + f(x + 8) + "," + f(y + 2);
    e.lx = x; e.ly = y - 50;
  }

  function route(g){
    var groups = {};
    g.edges.forEach(function(e){ var k = e.from.id + ">" + e.to.id; (groups[k] = groups[k] || []).push(e); });
    g.edges.forEach(function(e){
      var a = e.from, b = e.to;
      if (a === b) { loop(e, a); return; }
      var grp = groups[a.id + ">" + b.id], j = grp.indexOf(e), k = grp.length;
      var dx = b.x - a.x, dy = b.y - a.y, len2 = (dx * dx + dy * dy) || 1, len = Math.sqrt(len2);
      var nx = -dy / len, ny = dx / len, near = null;
      g.nodes.forEach(function(n){                             // a state on the line?
        if (n === a || n === b) return;
        var t = ((n.x - a.x) * dx + (n.y - a.y) * dy) / len2;
        if (t <= 0.04 || t >= 0.96) return;
        var d = (n.x - (a.x + t * dx)) * nx + (n.y - (a.y + t * dy)) * ny;
        if (Math.abs(d) < R + 30 && (near === null || Math.abs(d) < Math.abs(near))) near = d;
      });
      var span = Math.max(1, Math.abs(b.layer - a.layer));
      var bow = near === null ? 0 : (near > 0 ? -1 : 1) * (34 + 22 * (span - 1));   // bend away from it
      bow += (j - (k - 1) / 2) * 44;                                                 // fan out parallel edges
      curve(e, a, b, bow);
    });
    g.jumps.forEach(function(e){
      var span = Math.max(1, Math.abs(e.from.layer - e.to.layer));
      curve(e, e.from, e.to, e.from.x >= e.to.x ? 44 + 16 * span : -(44 + 16 * span));
    });
  }

  function measure(e){
    e.lw = Math.max(44, Math.max(e.event.length, e.action.length + 2) * 6.5 + 14);
    e.lh = (e.jump || !e.action) ? 18 : 32;
  }
  function relax(list){                                         // nudge overlapping labels apart
    for (var it = 0; it < 40; it++) {
      var moved = false;
      for (var i = 0; i < list.length; i++) for (var j = i + 1; j < list.length; j++) {
        var p = list[i], q = list[j];
        var ox = (p.lw + q.lw) / 2 + 6 - Math.abs(p.lx - q.lx);
        var oy = (p.lh + q.lh) / 2 + 4 - Math.abs(p.ly - q.ly);
        if (ox > 0 && oy > 0) {
          var push = oy / 2 + 0.5, dir = p.ly <= q.ly ? -1 : 1;
          p.ly += dir * push; q.ly -= dir * push; moved = true;
        }
      }
      if (!moved) break;
    }
  }

  function describe(n){
    var s = "state " + n.id;
    if (n.entry) s += ": mixed choice " + n.mc + " starts here";
    else if (n.jump) s += ": continue " + n.cont + ", to state " + n.jump.to.id;
    else if (n.end) s += ": terminal";
    else if (n.mc > 0) s += ": in mixed choice " + n.mc + (n.rhs ? ", right" : "");
    else s += ": outside mixed choice";
    if (n.rec.length) s += "; binds rec " + n.rec.join(", ");
    return s;
  }

  /* draw */
  function draw(g){
    var root = svg("svg", { "class": "efsm-svg", role: "group", "aria-label": "state machine" });
    var defs = svg("defs", null, root);
    ["lhs", "rhs", "none", "jump"].forEach(function(k){
      var mk = svg("marker", { id: "efsm-ah-" + k, viewBox: "0 0 10 10", refX: "8", refY: "5",
                               markerWidth: "7", markerHeight: "7", orient: "auto-start-reverse" }, defs);
      svg("path", { d: "M0,0 L10,5 L0,10 z", "class": "ah " + k }, mk);
    });
    var gE = svg("g", { "class": "edges" }, root), gL = svg("g", { "class": "labels" }, root),
        gN = svg("g", { "class": "nodes" }, root);
    var box = { x0: Infinity, y0: Infinity, x1: -Infinity, y1: -Infinity };
    function grow(x0, y0, x1, y1){
      box.x0 = Math.min(box.x0, x0); box.y0 = Math.min(box.y0, y0);
      box.x1 = Math.max(box.x1, x1); box.y1 = Math.max(box.y1, y1);
    }

    if (g.start) {
      var s = g.start;
      svg("path", { d: "M" + f(s.x - R - 46) + "," + f(s.y) + " L" + f(s.x - R - 5) + "," + f(s.y),
                    "class": "tr none", "marker-end": "url(#efsm-ah-none)" }, gE);
      var st = svg("text", { x: f(s.x - R - 46), y: f(s.y - 8), "class": "note" }, gL);
      st.textContent = "start";
      grow(s.x - R - 52, s.y - 20, s.x, s.y);
    }

    var all = g.edges.concat(g.jumps);
    all.forEach(function(e){
      e.path = svg("path", { d: e.d, "class": "tr " + e.side + (e.toRight ? " switch" : ""),
                             "marker-end": "url(#efsm-ah-" + e.side + ")" }, gE);
      e.hit = svg("path", { d: e.d, "class": "hit" }, gE);
      var lg = svg("g", { "class": "lbl " + e.side, transform: "translate(" + f(e.lx) + "," + f(e.ly) + ")" }, gL);
      svg("rect", { x: f(-e.lw / 2), y: f(-e.lh / 2), width: f(e.lw), height: e.lh, rx: 4 }, lg);
      if (e.jump || !e.action) {
        tspans(svg("text", { y: 4, "class": "ev" }, lg), parts(e.event, e));
      } else {
        tspans(svg("text", { y: -3, "class": "ev" }, lg), parts(e.event, e));
        tspans(svg("text", { y: 11, "class": "ac" }, lg), SLASH.slice(1).concat(parts(e.action, e)));
      }
      svg("title", null, lg).textContent = e.jump ? e.event : labelOf(e) + "  ·  " + SIDE[e.side];
      e.lbl = lg;
      grow(e.lx - e.lw / 2, e.ly - e.lh / 2, e.lx + e.lw / 2, e.ly + e.lh / 2);
    });

    g.nodes.forEach(function(n){
      var cls = "st" + (n.entry ? " entry" : "") + (n.end ? " end" : "") + (n.jump ? " cont" : "") +
                (n === g.start ? " start" : "");
      var ng = svg("g", { "class": cls, transform: "translate(" + f(n.x) + "," + f(n.y) + ")" }, gN);
      svg("circle", { r: R + 5, "class": "halo" }, ng);
      svg("circle", { r: R, "class": "ring" }, ng);
      if (n.end) svg("circle", { r: R - 4.5, "class": "inner" }, ng);
      svg("text", { y: 4, "class": "sid" }, ng).textContent = n.id;
      if (n.entry) svg("text", { y: -R - 8, "class": "badge mc" }, ng).textContent = "▷" + n.mc;
      if (n.jump)  svg("text", { y: R + 15, "class": "badge" }, ng).textContent = "↺ " + n.cont;
      svg("title", null, ng).textContent = describe(n);
      n.el = ng;
      grow(n.x - R - 8, n.y - R - 22, n.x + R + 8, n.y + R + 22);
    });

    var token = svg("circle", { r: 7, "class": "token", cx: -100, cy: -100 }, root);
    var m = 14, W = (box.x1 - box.x0) + 2 * m, H = (box.y1 - box.y0) + 2 * m;
    root.setAttribute("viewBox", f(box.x0 - m) + " " + f(box.y0 - m) + " " + f(W) + " " + f(H));
    root.style.width = "100%";
    root.style.maxWidth = Math.round(W) + "px";
    root.style.minWidth = Math.round(W * 0.85) + "px";      // then scroll
    return { root: root, token: token };
  }

  function drawIn(g){
    if (REDUCED) return;
    g.edges.forEach(function(e, i){
      var L = e.path.getTotalLength();
      e.path.style.strokeDasharray = L;
      e.path.style.strokeDashoffset = L;
      e.path.style.transition = "stroke-dashoffset .5s ease " + (i * 45) + "ms";
    });
    requestAnimationFrame(function(){ requestAnimationFrame(function(){
      g.edges.forEach(function(e){ e.path.style.strokeDashoffset = 0; });
    }); });
  }

  /* run */
  function runner(g, token, ui, mine){
    var cur = null, busy = false, playing = false, steps = 0, laps = 0, raf = 0, timer = 0;
    var all = g.edges.concat(g.jumps);
    function alive(){ return mine === gen; }
    function nexts(){ return !cur ? [] : cur.jump ? [cur.jump] : cur.out; }
    function place(p){ token.setAttribute("cx", f(p.x)); token.setAttribute("cy", f(p.y)); }
    function mark(){
      var nx = busy ? [] : nexts();
      g.nodes.forEach(function(n){ n.el.classList.toggle("cur", n === cur); });
      all.forEach(function(e){
        var on = nx.indexOf(e) >= 0;
        e.path.classList.toggle("next", on); e.hit.classList.toggle("next", on); e.lbl.classList.toggle("next", on);
      });
    }
    function setPlaying(on){ playing = on; ui.playing(on); }
    function take(e, done){
      if (busy || !alive()) return;
      busy = true; mark();
      ui.select(e);                                             // at the start: a later click can change it
      e.path.classList.add("hot"); e.lbl.classList.add("hot");
      token.classList.add("on");
      var len = e.path.getTotalLength(), ms = REDUCED ? 0 : Math.max(450, Math.min(950, len * 3.2)), t0 = null;
      place(e.path.getPointAtLength(0));
      function frame(ts){
        if (!alive()) return;
        if (t0 === null) t0 = ts;
        var k = ms ? Math.min(1, (ts - t0) / ms) : 1;
        var q = k < 0.5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2;
        place(e.path.getPointAtLength(len * q));
        if (k < 1) { raf = requestAnimationFrame(frame); return; }
        e.path.classList.remove("hot"); e.lbl.classList.remove("hot");
        cur = e.to; steps++; if (e.jump) laps++;
        place(cur); token.classList.remove("on");
        ui.push(e);
        busy = false; mark();
        if (cur.end) { ui.done(); setPlaying(false); }
        if (done) done();
      }
      raf = requestAnimationFrame(frame);
    }
    function choose(){
      var opts = nexts();
      if (!opts.length) return null;
      if (laps >= 2) {                                          // after two laps, prefer an exit
        var exits = opts.filter(function(e){ return e.toRight || e.to.end; });
        if (exits.length) opts = exits;
      }
      return opts[Math.floor(Math.random() * opts.length)];
    }
    function stop(){ setPlaying(false); clearTimeout(timer); cancelAnimationFrame(raf); }
    function reset(){
      stop(); busy = false; cur = g.start; steps = laps = 0;
      all.forEach(function(e){ e.path.classList.remove("hot"); e.lbl.classList.remove("hot"); });
      ui.clear(); token.classList.remove("on");
      if (cur) place(cur);
      mark();
    }
    function play(){
      if (!cur || cur.end) reset();
      setPlaying(true);
      (function next(){
        if (!playing || !alive()) return;
        var e = choose();
        if (!e || steps >= 40) { setPlaying(false); return; }
        take(e, function(){ if (playing) timer = setTimeout(next, REDUCED ? 250 : 380); });
      })();
    }
    all.forEach(function(e){                                   // click: select it; a highlighted one, take it too
      function click(){
        ui.select(e);
        if (busy || nexts().indexOf(e) < 0) return;
        setPlaying(false); clearTimeout(timer);
        take(e);
      }
      e.hit.addEventListener("click", click);
      e.lbl.addEventListener("click", click);
    });
    reset();
    return {
      play: play, reset: reset,
      pause: function(){ setPlaying(false); clearTimeout(timer); },
      step: function(){ if (playing || busy) return; if (!cur || cur.end) reset(); var e = choose(); if (e) take(e); },
      playing: function(){ return playing; }
    };
  }

  /* ui */
  // opts: role, the one to show first; types() and code(), promises of the local types by
  // role and of the generated files; openCode(file, line, to), to open a file at a clause.
  function render(host, machines, opts){
    opts = opts || {};
    gen++;
    host.innerHTML = "";
    var wrap = tag("div", "efsm", null, host);
    var top = tag("div", "efsm-top", null, wrap);
    var roles = tag("div", "efsm-roles", null, top);
    roles.setAttribute("role", "tablist");
    roles.setAttribute("aria-label", "Role");
    var ctl = tag("div", "efsm-ctl", null, top);
    var bPlay = tag("button", "btn", "▶ Play", ctl), bStep = tag("button", "btn", "Step", ctl),
        bReset = tag("button", "btn", "Reset", ctl);
    tag("p", "efsm-note", "The state machine each gen_<role>.erl implements. Click a transition to see its action " +
        "in the local type and its code below. Play, Step, or click a highlighted transition to run it.", wrap);
    var typeEl = tag("div", "efsm-type", null, wrap);
    typeEl.hidden = true;
    var canvas = tag("div", "efsm-canvas", null, wrap);
    var codeEl = tag("div", "efsm-code", null, wrap);
    codeEl.hidden = true;
    var trace = tag("div", "efsm-trace", null, wrap);
    tag("span", "lead", "run", trace);
    var ol = tag("ol", null, null, trace);
    var legend = tag("div", "efsm-legend", null, wrap);
    legend.innerHTML =
      '<span><i class="sw lhs"></i><span class="lt-lab lt-l">left</span></span>' +
      '<span><i class="sw rhs"></i><span class="lt-lab lt-r">right</span>, from the switch <code class="lt-op">*</code></span>' +
      '<span><i class="sw none"></i>outside</span>' +
      '<span><i class="sw jump"></i><code class="lt-kw">continue</code></span>' +
      '<span class="row">event <code class="lt-dot">/</code> action &middot; event: <code class="lt-op">?</code> message arrival, ' +
      '<code class="lt-kw">internal</code> the role\'s own step &middot; action: <code class="lt-op">!</code> send</span>' +
      '<span class="row"><code class="lt-op">?</code> alone: no action &middot; <code class="lt-op">*</code> switch to the right</span>' +
      '<span class="row"><code class="lt-op">▷1</code> mixed choice 1 starts here &middot; double ring: terminal</span>';

    var protos = {};
    machines.forEach(function(m){ protos[m.protocol] = true; });
    var many = Object.keys(protos).length > 1;
    var run = null, buttons = [], role = null, selected = null, asked = 0;

    var ui = {
      clear: function(){ ol.innerHTML = ""; tag("li", "empty", "nothing yet", ol); select(null); },
      push: function(e){
        var first = ol.querySelector(".empty"); if (first) ol.removeChild(first);
        spans(tag("li", e.side, null, ol), whole(e));
      },
      select: function(e){ select(e); },
      done: function(){ tag("li", "end", "■ end", ol); },
      playing: function(on){ bPlay.textContent = on ? "❚❚ Pause" : "▶ Play"; }
    };

    // The selected transition: its actions lit in the local type, its code below the diagram.
    function select(e){
      if (e === selected) return;
      if (selected) { selected.lbl.classList.remove("sel"); selected.path.classList.remove("sel"); }
      selected = e || null;
      if (selected) { selected.lbl.classList.add("sel"); selected.path.classList.add("sel"); }
      light();
      code();
    }
    function light(){
      Array.prototype.forEach.call(typeEl.querySelectorAll(".on"), function(x){ x.classList.remove("on"); });
      var e = selected;
      if (!e) return;
      acts(e).forEach(function(a){
        var q = '.lt-act[data-act="' + a.key + '"]';
        var hit = typeEl.querySelectorAll(q + '[data-mc="' + a.mc + '"][data-side="' + a.side + '"]');
        if (!hit.length) hit = typeEl.querySelectorAll(q);
        Array.prototype.forEach.call(hit, function(x){ x.classList.add("on"); });
      });
      var sw = e.toRight && typeEl.querySelector('.lt-mc[data-mc="' + e.from.mc + '"]');
      if (sw) sw.classList.add("on");
    }
    function code(){
      var e = selected, mine = ++asked;
      codeEl.innerHTML = "";
      codeEl.hidden = !e || !!e.jump;
      if (codeEl.hidden) return;
      var head = tag("div", "efsm-code-head", null, codeEl);
      tag("span", "lead", "code", head);
      spans(tag("span", "efsm-code-lbl", null, head), whole(e));
      tag("span", "efsm-code-st", "from state " + e.from.id + " to " + e.to.id, head);
      if (!opts.code) return;
      var body = tag("div", "efsm-code-body", "…", codeEl);
      opts.code().then(function(files){
        if (mine !== asked) return;
        body.textContent = "";
        var cs = clauses(files || [], role, e);
        if (!cs.length) { body.textContent = "No generated code for this transition."; return; }
        cs.forEach(function(c){
          var box = tag("div", "snip", null, body), h = tag("div", "snip-head", null, box);
          tag("code", null, c.file, h);
          tag("code", null, c.fn, h);
          tag("span", null, c.note, h);
          var a = tag("a", null, "line " + c.line, h);
          a.href = "#";
          a.title = "Open " + c.file + " in the Erlang tab";
          a.addEventListener("click", function(ev){ ev.preventDefault(); if (opts.openCode) opts.openCode(c.file, c.line, c.to); });
          tag("pre", "code", null, box).innerHTML = MMST.highlight(c.text, "erlang");
        });
      }, function(){ if (mine === asked) body.textContent = "No generated code: the server did not answer."; });
    }

    function show(i){
      gen++;
      var mine = gen, g = model(machines[i]);
      role = machines[i].role;
      selected = null;
      buttons.forEach(function(b, j){ b.setAttribute("aria-selected", j === i ? "true" : "false"); });
      g.edges.concat(g.jumps).forEach(measure); layout(g); route(g); relax(g.edges.concat(g.jumps));
      canvas.innerHTML = "";
      var d = draw(g);
      canvas.appendChild(d.root);
      drawIn(g);
      typeEl.hidden = true;
      typeEl.innerHTML = "";
      run = runner(g, d.token, ui, mine);
      if (opts.types && MMST.localType) opts.types().then(function(t){
        if (mine !== gen || !t || !t[role]) return;
        typeEl.innerHTML = '<span class="lead">local type</span><code class="ty">' + MMST.localType(t[role]) + "</code>";
        typeEl.hidden = false;
        light();
      }, function(){});
    }

    machines.forEach(function(m, i){
      var b = tag("button", null, many ? m.protocol + " · " + m.role : m.role, roles);
      b.setAttribute("role", "tab");
      b.addEventListener("click", function(){ show(i); });
      buttons.push(b);
    });
    bPlay.addEventListener("click", function(){ if (!run) return; if (run.playing()) run.pause(); else run.play(); });
    bStep.addEventListener("click", function(){ if (run) run.step(); });
    bReset.addEventListener("click", function(){ if (run) run.reset(); });
    var first = -1;
    machines.forEach(function(m, i){ if (first < 0 && opts.role && m.role === opts.role) first = i; });
    if (machines.length) show(Math.max(0, first));
  }

  MMST.efsm = { render: render };
})();

// index.html's script, in a file: the Content-Security-Policy runs no inline scripts.
(function(){
  "use strict";

  var SEED = [
    "module Scratch;",
    "",
    "// B observes: it goes along with A (left) or times out (right).",
    "",
    "global protocol Scratch(role A, role B, role C) {",
    "    mixed {",
    "        a1() from A to B;",
    "        a2() from A to C;",
    "        a3() from B to C;",
    "        a4() from B to A;",
    "        a5() from C to A;",
    "    } or A -> B {",
    "        TOa() from B to A;",
    "        TOc() from B to C;",
    "    }",
    "}"
  ].join("\n");

  var FLAG_NAMES = window.MMST.checks;

  function $(id){ return document.getElementById(id); }

  var MAC = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
  var src = $("src"), out = $("out"), status = $("status");
  var tabs = Array.prototype.slice.call(document.querySelectorAll(".tabs button")), view = "checks";
  function select(v){
    view = v;
    tabs.forEach(function(b){ b.setAttribute("aria-selected", b.getAttribute("data-view") === v ? "true" : "false"); });
  }

  function esc(s){ return String(s).replace(/[&<>]/g, function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;"}[c]; }); }
  function show(html){ out.innerHTML = html; out.scrollTop = 0; }

  // A local type as the checker prints it, B⊕a1() . [ … ▷1_B … ], in the paper's notation:
  // B ⊕ a1 . … ▷ …, spaced, without empty () or the outer brackets of a mixed choice. Labels
  // take the colour of their side of the innermost mixed choice; ▷ is numbered only when the
  // type has several. Branches l(): T read l . T.
  var LT = /▷(\d+)_([A-Za-z_][A-Za-z0-9_]*)|([⊕&])|([\[\]{},:.])|\(([^()]*)\)|([A-Za-z0-9_]+)|(\s+)|([^])/g;
  function localType(text){
    var toks = [], m;
    LT.lastIndex = 0;
    while ((m = LT.exec(text))) {
      if (m[1] !== undefined) toks.push({ t: "mc", n: m[1] });
      else if (m[3]) toks.push({ t: "op", s: m[3] });
      else if (m[4]) toks.push({ t: m[4] });
      else if (m[5] !== undefined) toks.push({ t: "pay", s: m[5].trim() });
      else if (m[6]) toks.push({ t: "w", s: m[6] });
      else if (!m[7]) toks.push({ t: "x", s: m[8] });
    }
    // The bracket pair around the whole type, if any, is left out.
    var outer = -1, depth = 0, i;
    if (toks.length && toks[0].t === "[") {
      for (i = 0; i < toks.length; i++) {
        if (toks[i].t === "[") depth++;
        else if (toks[i].t === "]" && --depth === 0) break;
      }
      if (i === toks.length - 1) outer = i;
    }
    var many = toks.filter(function(k){ return k.t === "mc"; }).length > 1;
    var stack = [], out = "", lab = false;            // lab: the next word is a label
    function side(){
      for (var j = stack.length - 1; j >= 0; j--) if (stack[j].mc) return stack[j].side;
      return "";
    }
    function label(s){ return '<span class="lt-lab' + (side() ? " lt-" + side() : "") + '">' + esc(s) + "</span>"; }
    for (i = 0; i < toks.length; i++) {
      var k = toks[i], next = toks[i + 1];
      if (k.t === "w") {
        if (lab) { out += label(k.s); lab = false;
          if (next && next.t === "pay") { i++; if (next.s) out += '<span class="lt-pay">(' + esc(next.s) + ")</span>"; }
          out += "</span>"; }
        else if (next && next.t === "op") out += '<span class="lt-act"><b class="lt-role">' + esc(k.s) + "</b>";
        else if (k.s === "end") out += '<span class="lt-end">end</span>';
        else if (k.s === "rec" && next && next.t === "w") { out += '<span class="lt-kw">μ</span><i class="lt-var">' + esc(next.s) + "</i>"; i++; }
        else if (stack.length && !stack[stack.length - 1].mc && stack[stack.length - 1].head) {
          out += '<span class="lt-act">' + label(k.s);            // a branch's label
          if (next && next.t === "pay") { i++; if (next.s) out += '<span class="lt-pay">(' + esc(next.s) + ")</span>"; }
          out += "</span>";
          stack[stack.length - 1].head = false;
        }
        else out += '<i class="lt-var">' + esc(k.s) + "</i>";
      }
      else if (k.t === "op") {                                 // closes the action's span before a {
        lab = !(next && next.t === "{");
        out += ' <span class="lt-op">' + k.s + "</span>" + (lab ? " " : "</span> ");
      }
      else if (k.t === "." || k.t === ":") out += '&nbsp;<span class="lt-dot">.</span> ';   // l(): T reads l . T
      else if (k.t === "mc") {
        if (stack.length && stack[stack.length - 1].mc) stack[stack.length - 1].side = "r";
        out += ' <span class="lt-op lt-mc">▷' + (many ? "<sub>" + k.n + "</sub>" : "") + "</span> ";
      }
      else if (k.t === "[") { stack.push({ mc: true, side: "l" }); if (i !== 0 || outer < 0) out += '<span class="lt-brk">[</span>'; }
      else if (k.t === "]") { stack.pop(); if (i !== outer) out += '<span class="lt-brk">]</span>'; }
      else if (k.t === "{") { stack.push({ mc: false, head: true }); out += '<span class="lt-brk">{</span> '; }
      else if (k.t === "}") { stack.pop(); out += ' <span class="lt-brk">}</span>'; }
      else if (k.t === ",") { if (stack.length && !stack[stack.length - 1].mc) stack[stack.length - 1].head = true; out += '<span class="lt-brk">,</span> '; }
      else if (k.t === "pay") { if (k.s) out += '<span class="lt-pay">(' + esc(k.s) + ")</span>"; }
      else out += esc(k.s);
    }
    return out;
  }

  function msg(kind, title, body){
    return '<div class="result"><div class="msg' + (kind ? " " + kind : "") + '">' +
           '<div class="t">' + esc(title) + '</div>' + esc(body) + '</div></div>';
  }

  // `x` as code; "line 9", "lines 9, 14" jump to the editor.
  function rich(s){
    return esc(s).replace(/`([^`]+)`/g, "<code>$1</code>")
      .replace(/\b(lines?) (\d+(?:, \d+)*)/g, function(all, word, ns){
        return ns.split(", ").map(function(n, i){
          return '<button class="loc" data-line="' + n + '">' + (i ? "" : word + " ") + n + '</button>';
        }).join(", ");
      });
  }

  // One line per problem: where, the construct, what.
  function where(ps){
    return '<div class="where">' + ps.map(function(p){
      return '<div><span class="ln"><button class="loc" data-line="' + p.line + '">line ' + p.line + '</button></span>' +
             (p.head ? '<code class="hd">' + esc(p.head) + '</code> ' : '') + rich(p.text) + '</div>';
    }).join("") + '</div>';
  }

  function renderFlags(flags, problems){
    var order = ["WF","SD","CT","BA"], firstFail = null, html = '<ul class="flags">';
    order.forEach(function(k){
      var pass = flags[k], mine = (problems || []).filter(function(p){ return p.kind === k; });
      if (!pass && firstFail === null) firstFail = k;
      html += '<li' + (!pass && firstFail === k ? ' class="first-fail"' : '') + '>' +
              '<b>' + k + '</b><span class="nm">' + FLAG_NAMES[k][0] + '</span>' +
              '<span class="dots"></span>' +
              '<span class="v ' + (pass ? "p" : "f") + '">' + (pass ? "PASS" : "FAIL") + '</span>' +
              (mine.length ? where(mine) : '') + '</li>';
    });
    return { html: html + "</ul>", firstFail: firstFail };
  }

  var TITLES = {
    parse: "Syntax error", scribble: "Scribble error", projection: "Projection fails",
    "inconsistent-choice": "Inconsistent choice", "mixed-roles": "Cannot translate",
    "after-mixed": "Cannot translate", "mixed-first": "Cannot translate", "empty-block": "Cannot translate",
    timeout: "Timed out"
  };

  // With these, the problem lines say all the error would.
  var QUIET = { parse: 1, scribble: 1, "mixed-first": 1, "empty-block": 1, "mixed-roles": 1 };

  function raw(r){
    return r.raw ? '<details class="raw"><summary>checker output</summary><pre class="raw">' + esc(r.raw) + '</pre></details>' : '';
  }

  function render(r){
    var ps = r.problems || [];
    mark(ps);
    if (!r.flags) {
      $("resultTitle").textContent = "not checked";
      var said = ps.length && QUIET[r.code];
      return show('<div class="result"><div class="msg"><div class="t">' + esc(TITLES[r.code] || "Not checked") + '</div>' +
                  (ps.length ? where(ps) : '') + (said ? '' : rich(r.error || "No result.")) + '</div>' + raw(r) + '</div>');
    }

    var f = renderFlags(r.flags, ps), h = '<div class="result">';
    h += '<div class="verdict"><span class="tag ' + (r.ok ? "ok" : "no") + '">' +
         (r.ok ? "valid" : "invalid") + '</span>' +
         (r.protocol ? '<span class="name">' + esc(r.protocol) + '</span>' : '') + '</div>';
    h += f.html;

    if (!r.ok) {
      var k = f.firstFail;
      h += '<p class="hintline"><b>' + k + ', ' + FLAG_NAMES[k][0] + '.</b> ' + FLAG_NAMES[k][1] + '</p>';
      h += '<p class="hintline">Fix the first <b>FAIL</b>: one error can fail two checks.</p>';
      $("resultTitle").textContent = "invalid";
    } else {
      h += '<h3 class="sec">local types</h3><ul class="locals">';
      (r.locals || []).forEach(function(l){
        h += '<li><span class="role">' + esc(l.role) + '</span><code class="ty" title="' +
             esc(l.type).replace(/"/g, "&quot;") + '">' + localType(l.type) + '</code></li>';
      });
      h += '</ul><p class="hintline" style="margin-top:1.2rem"><code class="lt-op">&#8853;</code> select (output-only choice)' +
           ' &nbsp;&middot;&nbsp; <code class="lt-op">&amp;</code> branch (input-only choice)' +
           ' &nbsp;&middot;&nbsp; <code class="lt-op">&#9655;</code> separates the <span class="lt-lab lt-l">left</span>' +
           ' and <span class="lt-lab lt-r">right</span> of a mixed choice, numbered when a type has several.' +
           ' The checker\'s own text is on hover.</p>';
      $("resultTitle").textContent = "valid";
    }

    show(h + raw(r) + "</div>");
  }

  var generated = null;
  function renderFiles(files){
    if (!files || !files.length) return show(msg("", "Nothing generated", "No files."));
    generated = files;
    var h = '<div class="files-bar"><span>' + esc(moduleName() || "Generated") +
            ': a <code>gen_</code> module per role, and callbacks to fill in.</span>' +
            '<button class="btn" id="toErlang" title="Edit and run in Erlang mode">Edit and run &rarr;</button></div>';
    h += '<div class="files">';
    files.forEach(function(f, i){
      h += '<button data-i="' + i + '"' + (i === 0 ? ' class="on"' : '') + '>' + esc(f.name) + '</button>';
    });
    h += '</div><pre class="code" id="fileBody">' + window.MMST.highlight(files[0].content, "erlang") + '</pre>';
    show(h);
    $("resultTitle").textContent = "generated erlang";
    $("toErlang").addEventListener("click", function(){
      window.MMST.erlang.openGenerated(moduleName() || "Scratch", generated);
      setMode("erlang");
    });
    Array.prototype.forEach.call(out.querySelectorAll(".files button"), function(b){
      b.addEventListener("click", function(){
        Array.prototype.forEach.call(out.querySelectorAll(".files button"), function(x){ x.classList.remove("on"); });
        b.classList.add("on");
        $("fileBody").innerHTML = window.MMST.highlight(files[+b.dataset.i].content, "erlang");
      });
    });
  }

  function renderEFSMPane(machines){
    if (!machines || !machines.length) return show(msg("", "Nothing to show", "No EFSMs."));
    window.MMST.efsm.render(out, machines);
    out.scrollTop = 0;
    $("resultTitle").textContent = "efsm";
  }

  function post(path, body){
    return fetch(path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    }).then(function(r){
      if (!r.ok) throw new Error("HTTP " + r.status);
      return r.json();
    });
  }

  function offline(e){
    $("resultTitle").textContent = "offline";
    show(msg("", "Offline",
      "The server is unreachable. Your protocol is still in the editor; ./mMST.sh checks it locally. (" + e.message + ")"));
  }

  function busy(on, label){
    $("check").disabled = on;
    tabs.forEach(function(b){ b.disabled = on; });
    status.textContent = on ? (label || "checking…") : "";
  }

  // Loaded, not checked: nothing runs until asked.
  function idle(){
    $("resultTitle").textContent = "not checked";
    show(msg("wait", "Not checked", "Press Check, or " + (MAC ? "\u2318\u21A9" : "Ctrl+\u21A9") + "."));
  }

  function check(){
    shown = true;
    select("checks");
    mark(null);
    busy(true);
    $("resultTitle").textContent = "checking";
    show(msg("wait", "Checking", ""));
    post("/api/validate", { source: src.value }).then(render).catch(offline)
      .then(function(){ busy(false); }, function(){ busy(false); });
  }

  function generate(){
    shown = true;
    select("erlang");
    mark(null);
    busy(true, "generating…");
    $("resultTitle").textContent = "generating";
    show(msg("wait", "Generating", ""));
    post("/api/generate", { source: src.value })
      .then(function(r){ if (r.ok && r.files) renderFiles(r.files); else render(r); })
      .catch(offline).then(function(){ busy(false); }, function(){ busy(false); });
  }

  function showEFSMs(){
    shown = true;
    select("efsm");
    mark(null);
    busy(true, "computing…");
    $("resultTitle").textContent = "computing";
    show(msg("wait", "Computing", ""));
    post("/api/efsm", { source: src.value })
      .then(function(r){ if (r.ok && r.machines) renderEFSMPane(r.machines); else render(r); })
      .catch(offline).then(function(){ busy(false); }, function(){ busy(false); });
  }

  function moduleName(){
    var m = /^\s*module\s+([A-Za-z_][A-Za-z0-9_]*)\s*;/m.exec(src.value);
    return m ? m[1] : null;
  }
  function syncName(){
    var m = moduleName();
    $("modname").textContent = m ? m + ".scr" : "no module declaration";
    $("modname").style.color = m ? "" : "var(--fail)";
  }

  // Marks from the last check: hard, the lines at fault; soft, the construct. Kept
  // while the line count stands, so they still point at the same lines.
  var hl = document.getElementById("hl"), marks = null;
  function lineCount(s){ return s.split("\n").length; }
  function mark(ps){
    marks = null;
    (ps || []).forEach(function(p){
      marks = marks || { at: {}, n: lineCount(src.value) };
      (p.soft || []).forEach(function(n){ if (!marks.at[n]) marks.at[n] = "esoft"; });
      (p.hard || []).forEach(function(n){ marks.at[n] = "eline"; });
    });
    syncHighlight();
  }
  function syncHighlight(){
    var html = window.MMST.highlight(src.value, "scribble");
    if (marks) {
      var lines = html.split("\n");
      Object.keys(marks.at).forEach(function(n){
        var i = +n - 1, m = i >= 0 && i < lines.length && /^(\s*)(\S.*)$/.exec(lines[i]);
        if (m) lines[i] = m[1] + '<mark class="' + marks.at[n] + '">' + m[2] + '</mark>';
      });
      html = lines.join("\n");
    }
    hl.innerHTML = html + "\n";
  }
  function keepMarks(){ if (marks && lineCount(src.value) !== marks.n) mark(null); }

  // Select a line, a third of the way down.
  function jump(line){
    var text = src.value, start = 0;
    for (var i = 1; i < line; i++) { start = text.indexOf("\n", start) + 1; if (!start) return; }
    var end = text.indexOf("\n", start);
    if (end < 0) end = text.length;
    while (start < end && /[ \t]/.test(text.charAt(start))) start++;
    src.focus({ preventScroll: true });
    try { src.setSelectionRange(start, end); } catch (e) {}
    var lh = parseFloat(getComputedStyle(src).lineHeight) || 20;
    src.scrollTop = Math.max(0, (line - 1) * lh - src.clientHeight / 3);
    src.scrollLeft = 0;
    hl.parentElement.scrollTop = src.scrollTop; hl.parentElement.scrollLeft = 0;
    if (window.matchMedia("(max-width:900px)").matches) src.scrollIntoView({ block: "nearest" });
  }
  out.addEventListener("click", function(e){
    var b = e.target.closest("button.loc[data-line]");
    if (b) jump(+b.dataset.line);
  });

  function decode(s){
    try { return decodeURIComponent(escape(atob(s.replace(/-/g,"+").replace(/_/g,"/")))); }
    catch (e) { return null; }
  }

  $("check").addEventListener("click", check);
  var VIEWS = { checks: check, efsm: showEFSMs, erlang: generate };
  tabs.forEach(function(b){ b.addEventListener("click", function(){ VIEWS[b.getAttribute("data-view")](); }); });
  src.addEventListener("input", syncName);
  src.addEventListener("input", keepMarks);
  src.addEventListener("input", syncHighlight);
  src.addEventListener("scroll", function(){
    var pre = hl.parentElement;
    pre.scrollTop = src.scrollTop; pre.scrollLeft = src.scrollLeft;
  });

  // The draft survives a visit to the other pages.
  var DRAFT = "mmst.draft";
  function saveDraft(){ try { sessionStorage.setItem(DRAFT, src.value); } catch (e) {} }
  function loadDraft(){ try { return sessionStorage.getItem(DRAFT); } catch (e) { return null; } }
  src.addEventListener("input", saveDraft);
  window.addEventListener("pagehide", saveDraft);

  src.addEventListener("keydown", function(e){
    if (e.key === "Tab" && !e.metaKey && !e.ctrlKey && !e.altKey) {
      e.preventDefault();
      src.setRangeText("    ", src.selectionStart, src.selectionEnd, "end");
      syncName();
      keepMarks();
      syncHighlight();
    }
  });
  document.addEventListener("keydown", function(e){
    if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
      e.preventDefault();
      if (mode === "erlang") window.MMST.erlang.run(); else check();
    }
  });

  // Two modes; the Erlang mode generates from the protocol editor.
  var mode = "protocol", shown = false;
  var modeButtons = Array.prototype.slice.call(document.querySelectorAll(".modes button"));
  function setMode(m, want){
    var was = mode;
    mode = m;
    $("protocol-main").hidden = m !== "protocol";
    $("erlang-main").hidden = m !== "erlang";
    $("examples").hidden = m !== "protocol";
    $("erlsets").hidden = m !== "erlang";
    modeButtons.forEach(function(b){ b.setAttribute("aria-selected", b.getAttribute("data-mode") === m ? "true" : "false"); });
    if (m === "erlang") return window.MMST.erlang.enter(want);
    if (was === "erlang") window.MMST.erlang.leave();
    history.replaceState(null, "", $("examples").value ? "#ex=" + encodeURIComponent($("examples").value)
                                                       : location.pathname + location.search);
    if (!shown) idle();
  }
  modeButtons.forEach(function(b){ b.addEventListener("click", function(){ setMode(b.getAttribute("data-mode")); }); });

  // Menu: the exercises, then a link to the examples page. Every protocol opens by #ex=NAME,
  // in the menu or not: the examples page links to the others that way.
  var byId = {}, sel = $("examples"), MORE = "examples.html";
  function fillMenu(list){
    var E = window.MMST.examples;
    list.forEach(function(x){ byId[x.id] = x; });
    (E ? E.arrange(list, false).filter(function(g){ return /^Exercise \d+$/.test(g.group); })
       : [{ group: "Protocols", items: list }]).forEach(function(g){
      if (!g.items.length) return;
      var og = document.createElement("optgroup");
      og.label = g.group;
      g.items.forEach(function(x){
        var o = document.createElement("option");
        o.value = x.id; o.textContent = E ? E.title(x.id) : x.id;
        og.appendChild(o);
      });
      sel.appendChild(og);
    });
    var rule = document.createElement("option"), more = document.createElement("option");
    rule.disabled = true; rule.textContent = "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500";
    more.value = MORE; more.textContent = "More on the examples page\u2026";
    sel.appendChild(rule); sel.appendChild(more);
  }

  // From the menu or #ex=NAME[&view=efsm]; the hash names it until the first edit.
  function load(id, v){
    var x = byId[id];
    if (!x) return false;
    src.value = x.source;
    syncName();
    mark(null);
    sel.value = id;
    if (sel.value !== id) sel.value = "";                 // not in the menu: show its prompt
    history.replaceState(null, "", "#ex=" + encodeURIComponent(id));
    if (VIEWS[v]) VIEWS[v](); else idle();
    return true;
  }
  sel.addEventListener("change", function(){
    if (sel.value === MORE) { sel.value = ""; location.href = MORE; return; }
    if (sel.value) load(sel.value);
  });
  src.addEventListener("input", function(){
    if (sel.value) sel.value = "";
    if (/[#&]ex=/.test(location.hash)) history.replaceState(null, "", location.pathname + location.search);
  });

  var menu = Promise.all([
      fetch("/api/examples").then(function(r){ if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); }),
      window.MMST.examples ? window.MMST.examples.ready : null        // order and titles, from text/examples.md
    ]).then(function(r){ fillMenu(r[0].examples || []); window.MMST.erlang.refresh(); });

  function unescapeHash(s){ try { return decodeURIComponent(s); } catch (e) { return s; } }
  var hash = location.hash;
  var p = /[#&]p=([A-Za-z0-9_-]+)/.exec(hash), seeded = p && decode(p[1]);
  var ex = /[#&]ex=([^&]+)/.exec(hash), wanted = /[#&]view=(checks|efsm|erlang)(?:&|$)/.exec(hash);
  $("kbdhint").textContent = document.querySelector("#erl-run .kbd").textContent = MAC ? "\u2318\u21A9" : "Ctrl+\u21A9";

  window.MMST.erlang.init({
    post: post,
    protocol: function(){ return src.value; },
    moduleName: moduleName,
    hasProtocol: function(id){ return !!byId[id]; },
    openProtocol: function(id){ shown = true; setMode("protocol"); if (!load(id)) idle(); }
  });
  var erl = /[#&]mode=erlang(?:&|$)/.test(hash), erlId = /[#&]erl=([^&]+)/.exec(hash);

  src.value = seeded || loadDraft() || SEED;
  syncName();
  syncHighlight();
  window.MMST.lineNumbers(src, hl);
  // Start: #mode=erlang, else #p=, else #ex= (once the menu is in), else the draft or the starter.
  if (erl) {
    menu["catch"](function(){});
    setMode("erlang", erlId ? unescapeHash(erlId[1]) : undefined);
  } else if (ex && !seeded) {
    menu.then(function(){
      if (load(unescapeHash(ex[1]), wanted && wanted[1])) return;
      history.replaceState(null, "", location.pathname + location.search);   // no such example
      idle();
    }, idle);
  } else {
    menu["catch"](function(){});
    idle();
  }
})();

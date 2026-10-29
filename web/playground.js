// index.html's script, in a file: the Content-Security-Policy runs no inline scripts.
(function(){
  "use strict";

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
  var empty = false;                                  // the pane says the editor is empty
  function show(html){ out.innerHTML = html; out.scrollTop = 0; empty = false; }

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

  // The four checks; with onto, the role the checker cannot project onto once they pass.
  function renderFlags(flags, problems, onto){
    var order = ["WF","SD","CT","BA"], html = '<ul class="flags">';
    order.forEach(function(k){
      var pass = flags[k], mine = (problems || []).filter(function(p){ return p.kind === k; });
      html += '<li' + (pass ? '' : ' class="fail"') + '>' +
              '<b>' + k + '</b><span class="nm">' + FLAG_NAMES[k][0] + '</span>' +
              '<span class="dots"></span>' +
              '<span class="v ' + (pass ? "p" : "f") + '">' + (pass ? "PASS" : "FAIL") + '</span>' +
              (mine.length ? where(mine) : '') + '</li>';
    });
    if (onto) {
      var mine = (problems || []).filter(function(p){ return p.kind === "projection"; });
      html += '<li class="fail"><b></b><span class="nm">projection onto ' + esc(onto) + '</span>' +
              '<span class="dots"></span><span class="v f">FAIL</span>' + (mine.length ? where(mine) : '') + '</li>';
    }
    return html + "</ul>";
  }

  var TITLES = {
    parse: "Syntax error", scribble: "Scribble error", projection: "Projection fails",
    "inconsistent-choice": "Inconsistent choice", "mixed-roles": "Cannot translate",
    "after-mixed": "Cannot translate", "mixed-first": "Cannot translate", "empty-block": "Cannot translate",
    timeout: "Timed out", busy: "Busy"
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

    var onto = r.code === "projection" ? r.onto || "?" : null;
    var h = '<div class="result">';
    h += '<div class="verdict"><span class="tag ' + (r.ok ? "ok" : "no") + '">' +
         (r.ok ? "valid" : "invalid") + '</span>' +
         (r.protocol ? '<span class="name">' + esc(r.protocol) + '</span>' : '') + '</div>';
    h += renderFlags(r.flags, ps, onto);

    if (!r.ok) {
      if (onto && !ps.length && r.error) h += '<p class="hintline">' + rich(r.error) + '</p>';   // no lines to show
      $("resultTitle").textContent = "invalid";
    } else {
      h += '<h3 class="sec">local types</h3><ul class="locals">';
      (r.locals || []).forEach(function(l){
        h += '<li><span class="role">' + esc(l.role) + '</span><code class="ty">' + window.MMST.localType(l.type) + '</code></li>';
      });
      h += '</ul><p class="hintline" style="margin-top:1.2rem"><code class="lt-op">&#8853;</code> select (output-only choice)' +
           ' &nbsp;&middot;&nbsp; <code class="lt-op">&amp;</code> branch (input-only choice)' +
           ' &nbsp;&middot;&nbsp; <code class="lt-op">&#9655;</code> separates the <span class="lt-lab lt-l">left</span>' +
           ' and <span class="lt-lab lt-r">right</span> of a mixed choice, numbered when a type has several.</p>';
      $("resultTitle").textContent = "valid";
    }

    show(h + raw(r) + "</div>");
  }

  var generated = null;
  // want, from the EFSM view's code: { file, line, to }, that file open with those lines marked.
  function renderFiles(files, want){
    if (!files || !files.length) return show(msg("", "Nothing generated", "No files."));
    generated = files;
    var at = 0;
    if (want && want.file) files.forEach(function(f, i){ if (f.name === want.file) at = i; });
    var h = '<div class="files-bar"><span>' + esc(moduleName() || "Generated") +
            ': a <code>gen_</code> module per role, and callbacks to fill in.</span>' +
            '<button class="btn" id="toErlang" title="Edit and run in Erlang mode">Edit and run &rarr;</button></div>';
    h += '<div class="files">';
    files.forEach(function(f, i){
      h += '<button data-i="' + i + '"' + (i === at ? ' class="on"' : '') + '>' + esc(f.name) + '</button>';
    });
    // The parser drops a newline right after <pre>: this one, not the file's, so lines stay numbered.
    h += '</div><pre class="code" id="fileBody">\n' + window.MMST.highlight(files[at].content, "erlang") + '</pre>';
    show(h);
    if (want && want.line) markLines($("fileBody"), want.line, want.to || want.line);
    $("resultTitle").textContent = "generated erlang";
    $("toErlang").addEventListener("click", function(){
      editor(true);
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

  // A band behind lines from..to of a file, scrolled to the middle.
  function markLines(pre, from, to){
    var cs = getComputedStyle(pre), lh = parseFloat(cs.lineHeight) || parseFloat(cs.fontSize) * 1.6;
    var band = document.createElement("span");
    band.className = "code-band";
    band.style.top = ((parseFloat(cs.paddingTop) || 0) + (from - 1) * lh) + "px";
    band.style.height = ((to - from + 1) * lh) + "px";
    pre.appendChild(band);
    band.scrollIntoView({ block: "center" });
  }

  // The EFSMs of text; role: the one to show first. The local types and the generated code
  // come when asked for: the type above the diagram, the code of a transition below it.
  function renderEFSMPane(machines, text, role){
    if (!machines || !machines.length) return show(msg("", "Nothing to show", "No EFSMs."));
    var types = null, code = null;
    window.MMST.efsm.render(out, machines, {
      role: role,
      types: function(){
        return types || (types = post("/api/validate", { source: text }).then(function(r){
          var t = {};
          (r.locals || []).forEach(function(l){ if (!(l.role in t)) t[l.role] = l.type; });
          return t;
        }));
      },
      code: function(){
        return code || (code = post("/api/generate", { source: text }).then(function(r){ return r.ok && r.files ? r.files : []; }));
      },
      openCode: function(file, line, to){ generate({ file: file, line: line, to: to }); }
    });
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
      "The server is unreachable. Your protocol is still in the editor. (" + e.message + ")"));
  }

  function busy(on, label){
    $("check").disabled = on;
    tabs.forEach(function(b){ b.disabled = on; });
    status.textContent = on ? (label || "checking…") : "";
  }

  // Loaded, not checked: nothing runs until asked. An empty editor says so until written in.
  function idle(){
    var none = !src.value.trim();
    $("resultTitle").textContent = none ? "empty" : "not checked";
    show(none ? msg("wait", "Empty", "Write a protocol, or load one from the menu.")
              : msg("wait", "Not checked", "Press Check, or " + (MAC ? "\u2318\u21A9" : "Ctrl+\u21A9") + "."));
    empty = none;
  }
  function blank(){ if (src.value.trim()) return false; mark(null); idle(); return true; }

  function check(){
    shown = true;
    select("checks");
    if (blank()) return;
    mark(null);
    busy(true);
    $("resultTitle").textContent = "checking";
    show(msg("wait", "Checking", ""));
    post("/api/validate", { source: src.value }).then(render).catch(offline)
      .then(function(){ busy(false); }, function(){ busy(false); });
  }

  function generate(want){
    shown = true;
    select("erlang");
    if (blank()) return;
    mark(null);
    busy(true, "generating…");
    $("resultTitle").textContent = "generating";
    show(msg("wait", "Generating", ""));
    post("/api/generate", { source: src.value })
      .then(function(r){ if (r.ok && r.files) renderFiles(r.files, want); else render(r); })
      .catch(offline).then(function(){ busy(false); }, function(){ busy(false); });
  }

  function showEFSMs(role){
    var text = src.value;
    shown = true;
    select("efsm");
    if (blank()) return;
    mark(null);
    busy(true, "computing…");
    $("resultTitle").textContent = "computing";
    show(msg("wait", "Computing", ""));
    post("/api/efsm", { source: text })
      .then(function(r){ if (r.ok && r.machines) renderEFSMPane(r.machines, text, role); else render(r); })
      .catch(offline).then(function(){ busy(false); }, function(){ busy(false); });
  }

  function moduleName(){
    var m = /^\s*module\s+([A-Za-z_][A-Za-z0-9_]*)\s*;/m.exec(src.value);
    return m ? m[1] : null;
  }
  function syncName(){
    var m = moduleName(), none = !src.value.trim();
    $("modname").textContent = m ? m + ".scr" : none ? "" : "no module declaration";
    $("modname").style.color = m || none ? "" : "var(--fail)";
  }

  // Marks from the last check: hard, the lines at fault; soft, the construct, or the side or
  // branch where a role is missing. Kept while the line count stands, so they still point at
  // the same lines.
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
    if (b) { editor(true); jump(+b.dataset.line); }
  });

  // The header's editor button hides and shows the editor, in both modes. Hidden, the other
  // pane takes the full width, and Check and its status move to the results' head.
  var editorHidden = false, mains = [$("protocol-main"), $("erlang-main")];
  var leftHead = $("check").parentNode, rightHead = out.parentNode.querySelector(".pane-head .right");
  function editor(show){
    if (editorHidden !== show) return;
    editorHidden = !show;
    mains.forEach(function(m){ m.classList.toggle("no-editor", editorHidden); });
    var to = show ? leftHead : rightHead, before = show ? null : rightHead.querySelector(".tabs");
    to.insertBefore(status, before);
    to.insertBefore($("check"), before);
    syncEditorButton();
  }
  function syncEditorButton(){
    var b = document.querySelector("#site-header button[data-editor]");
    if (!b) return;
    b.setAttribute("aria-controls", "protocol-left erlang-left");
    b.setAttribute("aria-pressed", editorHidden ? "false" : "true");
    b.title = editorHidden ? "Show the editor" : "Hide the editor";
  }
  $("site-header").addEventListener("click", function(e){
    if (e.target.closest("button[data-editor]")) editor(editorHidden);
  });
  window.MMST.ready.then(syncEditorButton);

  function decode(s){
    try { return decodeURIComponent(escape(atob(s.replace(/-/g,"+").replace(/_/g,"/")))); }
    catch (e) { return null; }
  }

  $("check").addEventListener("click", check);
  var VIEWS = { checks: check, efsm: showEFSMs, erlang: generate };
  tabs.forEach(function(b){ b.addEventListener("click", function(){ VIEWS[b.getAttribute("data-view")](); }); });
  src.addEventListener("input", syncName);
  src.addEventListener("input", function(){ if (empty && src.value.trim()) idle(); });
  src.addEventListener("input", keepMarks);
  src.addEventListener("input", syncHighlight);
  src.addEventListener("scroll", function(){
    var pre = hl.parentElement;
    pre.scrollTop = src.scrollTop; pre.scrollLeft = src.scrollLeft;
  });

  // The draft comes back after a visit to the other pages. Opened afresh or reloaded, or
  // from the brand (?new), the editor is empty, even when the address names an example.
  var DRAFT = "mmst.draft";
  function saveDraft(){
    try {
      sessionStorage.setItem(DRAFT, src.value);
      sessionStorage.setItem(DRAFT + ".from", current ? current.id : "");    // its menu entry
    } catch (e) {}
  }
  function navType(){
    try { var n = performance.getEntriesByType("navigation")[0]; return n ? n.type : "navigate"; }
    catch (e) { return "navigate"; }
  }
  function returning(){
    var type = navType();
    if (type === "back_forward") return true;
    if (type !== "navigate" || !document.referrer) return false;
    try { var r = new URL(document.referrer); return r.origin === location.origin && r.pathname !== location.pathname; }
    catch (e) { return false; }
  }
  function loadDraft(){
    if (!returning()) return null;
    try {
      var d = sessionStorage.getItem(DRAFT), from = sessionStorage.getItem(DRAFT + ".from");
      if (d && from) current = { id: from, edited: true };                 // settled once the menu is in
      return d;
    } catch (e) { return null; }
  }
  src.addEventListener("input", saveDraft);
  window.addEventListener("pagehide", saveDraft);

  src.addEventListener("keydown", function(e){
    if (e.key === "Tab" && !e.metaKey && !e.ctrlKey && !e.altKey) {
      e.preventDefault();
      window.MMST.insertText(src, "    ");
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
    named();
    if (!shown) idle();
  }
  modeButtons.forEach(function(b){ b.addEventListener("click", function(){ setMode(b.getAttribute("data-mode")); }); });

  // Menu: the exercises, the examples page's cards, then a link to the page. Every protocol
  // opens by #ex=NAME, in the menu or not: the examples page links to the others that way.
  var byId = {}, sel = $("examples"), MORE = "examples.html";
  function fillMenu(list){
    var E = window.MMST.examples;
    list.forEach(function(x){ byId[x.id] = x; });
    (E ? E.arrange(list, false).filter(function(g){ return /^Exercise \d+$/.test(g.group) || g.group === "Examples"; })
       : [{ group: "Protocols", items: list }]).forEach(function(g){
      if (!g.items.length) return;
      var og = document.createElement("optgroup");
      og.label = (E && E.menu[g.group]) || g.group;
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

  // The menu shows what the editor holds: its entry, or its edited entry, or, for a protocol the
  // menu does not list, an entry of its own at the top. A protocol's edits are kept for the
  // session, through other picks and reloads: its edited entry, after its own, brings them
  // back. Picking an entry loads it as it was, even the one in hand.
  var current = null, EDITS = "mmst.edits", edits = readEdits(), drawn = null;   // current: { id, edited }
  function readEdits(){
    try { var e = JSON.parse(sessionStorage.getItem(EDITS) || "{}"); return e && typeof e === "object" ? e : {}; }
    catch (x) { return {}; }
  }
  function keepEdit(){                                  // the protocol in hand's edits, or none
    if (!current) return;
    if (current.edited) edits[current.id] = src.value; else delete edits[current.id];
    try { sessionStorage.setItem(EDITS, JSON.stringify(edits)); } catch (x) {}
  }
  function lf(s){ return s.replace(/\r\n?/g, "\n"); }
  function settle(){                                    // edited: not the protocol as it was
    var x = current && byId[current.id];
    if (current && !x) current = null;
    else if (current) current.edited = lf(src.value) !== lf(x.source);
  }
  function title(id){ return window.MMST.examples ? window.MMST.examples.title(id) : id; }
  function entry(id){                                   // its own option in the menu, if listed
    for (var i = 0; i < sel.options.length; i++)
      if (sel.options[i].value === id && !sel.options[i].classList.contains("kept")) return sel.options[i];
    return null;
  }
  function syncMenu(){
    if (current && current.edited && edits[current.id] !== src.value) keepEdit();
    var ids = Object.keys(edits).filter(function(id){ return byId[id]; }).sort();
    var other = current && !current.edited && !entry(current.id) ? current.id : null;
    var key = ids.join("\n") + "\n\n" + (other || "");
    if (key !== drawn) {                                // the kept and the unlisted entries, again
      drawn = key;
      Array.prototype.slice.call(sel.querySelectorAll("option.kept")).forEach(function(o){ o.remove(); });
      var top = sel.options[0];                         // the prompt; unlisted ones go after it
      if (other) top = kept("shown:" + other, title(other), top);
      ids.forEach(function(id){
        var own = entry(id);
        if (own) kept("edited:" + id, title(id) + ", edited", own);
        else top = kept("edited:" + id, title(id) + ", edited", top);
      });
    }
    sel.value = !current ? "" : current.edited ? "edited:" + current.id
              : other ? "shown:" + current.id : current.id;
  }
  function kept(value, text, after){                    // an entry of the menu's own, after another
    var o = document.createElement("option");
    o.value = value; o.textContent = text; o.className = "kept";
    after.parentNode.insertBefore(o, after.nextSibling);
    return o;
  }
  // The address names the protocol until it is edited: #ex=NAME.
  function named(){
    var h = current && !current.edited ? "#ex=" + encodeURIComponent(current.id) : "";
    if (location.hash !== h) history.replaceState(null, "", h || location.pathname + location.search);
  }

  // From the menu or #ex=NAME[&view=efsm[&role=R]].
  function load(id, v, role){
    var x = byId[id];
    if (!x) return false;
    src.value = x.source;
    syncName();
    mark(null);
    current = { id: id, edited: false };
    syncMenu();
    history.replaceState(null, "", "#ex=" + encodeURIComponent(id));
    saveDraft();
    if (v === "efsm") showEFSMs(role); else if (VIEWS[v]) VIEWS[v](); else idle();
    return true;
  }
  // A kept edit, back in the editor.
  function loadEdited(id){
    if (typeof edits[id] !== "string" || !byId[id]) return false;
    src.value = edits[id];
    syncName();
    mark(null);
    current = { id: id, edited: true };
    settle();
    syncMenu();
    named();
    saveDraft();
    idle();
    return true;
  }
  sel.addEventListener("change", function(){
    var v = sel.value;
    if (v === MORE) { syncMenu(); location.href = MORE; return; }
    if (v.indexOf("edited:") === 0) loadEdited(v.slice(7));
    else if (v.indexOf("shown:") === 0) load(v.slice(6));
    else if (v) load(v);
  });
  src.addEventListener("input", function(){
    if (!current) return;
    if (!src.value.trim()) current = null; else { settle(); keepEdit(); }
    syncMenu();
    named();
    saveDraft();
  });

  var menu = Promise.all([
      fetch("/api/examples").then(function(r){ if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); }),
      window.MMST.examples ? window.MMST.examples.ready : null        // order and titles, from text/examples.md
    ]).then(function(r){ fillMenu(r[0].examples || []); window.MMST.erlang.refresh(); });

  function unescapeHash(s){ try { return decodeURIComponent(s); } catch (e) { return s; } }
  var hash = location.hash;
  var p = /[#&]p=([A-Za-z0-9_-]+)/.exec(hash), seeded = p && decode(p[1]);
  var ex = /[#&]ex=([^&]+)/.exec(hash), wanted = /[#&]view=(checks|efsm|erlang)(?:&|$)/.exec(hash);
  var wantRole = /[#&]role=([^&]+)/.exec(hash);
  $("kbdhint").textContent = document.querySelector("#erl-run .kbd").textContent = MAC ? "\u2318\u21A9" : "Ctrl+\u21A9";

  window.MMST.erlang.init({
    post: post,
    protocol: function(){ return src.value; },
    moduleName: moduleName,
    hasProtocol: function(id){ return !!byId[id]; },
    openProtocol: function(id){ shown = true; editor(true); setMode("protocol"); if (!load(id)) idle(); },
    showEditor: function(){ editor(true); }
  });
  var erl = /[#&]mode=erlang(?:&|$)/.test(hash), erlId = /[#&]erl=([^&]+)/.exec(hash);

  var fresh = location.search === "?new";
  if (fresh) history.replaceState(null, "", location.pathname + location.hash);
  src.value = seeded || (fresh ? "" : loadDraft()) || "";
  if (seeded || !src.value) current = null;
  syncName();
  syncHighlight();
  window.MMST.lineNumbers(src, hl);
  // Start: #mode=erlang, else #p=, else #ex= (once the menu is in) unless reloaded, else the
  // draft, else empty.
  if (ex && !erl && navType() === "reload") { ex = null; history.replaceState(null, "", location.pathname + location.search); }
  menu.then(function(){ settle(); syncMenu(); }, function(){});
  if (erl) {
    menu["catch"](function(){});
    setMode("erlang", erlId ? unescapeHash(erlId[1]) : undefined);
  } else if (ex && !seeded) {
    menu.then(function(){
      if (load(unescapeHash(ex[1]), wanted && wanted[1], wantRole ? unescapeHash(wantRole[1]) : null)) return;
      history.replaceState(null, "", location.pathname + location.search);   // no such example
      idle();
    }, idle);
  } else {
    menu["catch"](function(){});
    idle();
  }
})();

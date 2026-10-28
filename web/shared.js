/* Shared by all pages: theme, the four checks, highlighting, local types, editor line
   numbers, and the parts every page pulls in: header.html, footer.html, Markdown text
   (data-md) and HTML parts (data-include). MMST.ready settles once they are all in place. */
(function(){
  "use strict";

  try {
    var saved = localStorage.getItem("mmst.theme");
    if (saved) document.documentElement.setAttribute("data-theme", saved);
  } catch (e) {}

  var MMST = window.MMST = window.MMST || {};

  MMST.order  = ["WF", "SD", "CT", "BA"];
  MMST.checks = {
    WF: ["well-formed",       "Each label is committing everywhere or nowhere, so a receiver knows which side of the mixed choice it is on."],
    SD: ["single-decision",   "On the right, every role depends on the observer: an overrule reaches everyone."],
    CT: ["clear-termination", "On the left, the observer reaches every role, directly or transitively: no role finishes without learning the observer's decision."],
    BA: ["balanced",          "The branches of a choice involve the same roles: nobody waits for a message only one branch sends."]
  };

  // Regex highlighter for Scribble and Erlang.
  var KEYWORDS = {
    scribble: ["module","global","protocol","role","mixed","choice","at","from","to","or","rec","continue","data","as","import"],
    erlang:   ["case","of","end","fun","when","receive","after","if","andalso","orelse","not","and","or",
               "module","export","spec","record","define","behaviour","behavior","let","try","catch","throw","exit"]
  };
  function escHtml(s){ return String(s).replace(/[&<>]/g, function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;"}[c]; }); }
  MMST.highlight = function(text, lang){
    var kw = KEYWORDS[lang] || KEYWORDS.scribble;
    var commentSrc = lang === "erlang" ? "%[^\\n]*" : "//[^\\n]*";
    var tokenRe = new RegExp(
      "(" + commentSrc + ")" +                    // 1 comment
      "|(\"(?:\\\\.|[^\"\\\\])*\")" +              // 2 double-quoted string
      "|('(?:\\\\.|[^'\\\\])*')" +                 // 3 single-quoted atom (Erlang)
      "|(\\b\\d+(?:\\.\\d+)?\\b)" +                // 4 number
      "|(\\b(?:" + kw.join("|") + ")\\b)" +        // 5 keyword
      "|([A-Z][A-Za-z0-9_]*)",                     // 6 role / variable / Erlang Var
      "g"
    );
    return escHtml(text).replace(tokenRe, function(m, com, str, atom, num, k, id){
      if (com)  return '<span class="tok-com">' + com + '</span>';
      if (str)  return '<span class="tok-str">' + str + '</span>';
      if (atom) return '<span class="tok-str">' + atom + '</span>';
      if (num)  return '<span class="tok-num">' + num + '</span>';
      if (k)    return '<span class="tok-kw">' + k + '</span>';
      if (id)   return '<span class="tok-var">' + id + '</span>';
      return m;
    });
  };

  // Global and local types, as in the paper: A→B:a1 . … ⊳ …, B⊕a1 . C&a5 . end, Shop⊕{buy: end, …}.
  // Roles, labels, ⊕ and &, the ⊳ between the sides, end, // comments, ✓ and ✗.
  var MARKS = { "✓": "tok-ok", "✗": "tok-bad", "⊳": "tok-mc", "▷": "tok-mc", "⊕": "tok-op", "&": "tok-op", "→": "tok-arrow" };
  MMST.highlightTypes = function(text){
    var out = "", re = /(\/\/[^\n]*)|([✓✗⊳▷⊕&→])|([A-Za-z_][A-Za-z0-9_]*)|([^\/✓✗⊳▷⊕&→A-Za-z_]+|\/)/g, m;
    function span(cls, s){ return '<span class="' + cls + '">' + escHtml(s) + '</span>'; }
    while ((m = re.exec(text))) {
      if (m[1]) { out += span("tok-com", m[1]); continue; }
      if (m[2]) { out += span(MARKS[m[2]], m[2]); continue; }
      if (m[4] !== undefined) { out += escHtml(m[0]); continue; }
      var id = m[3], before = text.slice(0, m.index).replace(/[ \t]+$/, ""), after = text.slice(re.lastIndex);
      var prev = before.slice(-1), next = after.replace(/^[ \t]+/, "").charAt(0);
      if (id === "end") out += span("tok-kw", id);
      else if (next === "⊕" || next === "&" || next === "→" || prev === "→" ||
               (next === ":" && /(^|\n)[ \t]*$/.test(before))) out += span("tok-role", id);
      else if ("⊕&:{,".indexOf(prev) >= 0 && prev) out += span("tok-label", id);
      else out += escHtml(id);
    }
    return out;
  };

  // A local type as the checker prints it, B⊕a1() . [ … ▷1_B … ], in the paper's notation:
  // B ⊕ a1 . … ▷ …, spaced, without empty () or the outer brackets of a mixed choice. Labels
  // take the colour of their side of the innermost mixed choice; ▷ is numbered only when the
  // type has several. Branches l(): T read l . T. Each action carries where it is, for the
  // EFSM view: data-act "role ! label" or "role ? label", data-mc and data-side, the innermost
  // mixed choice and its side. The playground's local types, its EFSM view, and ```local.
  var LT =/▷(\d+)_([A-Za-z_][A-Za-z0-9_]*)|([⊕&])|([\[\]{},:.])|\(([^()]*)\)|([A-Za-z0-9_]+)|(\s+)|([^])/g;
  MMST.localType = function(text){
    var esc = escHtml, toks = [], m;
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
    var frames = [];                                  // mixed choices, in the order their [ opens
    function frame(){
      for (var j = stack.length - 1; j >= 0; j--) if (stack[j].mc) return stack[j];
      return null;
    }
    function side(){ var fr = frame(); return fr ? fr.side : ""; }
    function label(s){ return '<span class="lt-lab' + (side() ? " lt-" + side() : "") + '">' + esc(s) + "</span>"; }
    function at(role, op, l){                         // its ▷ number is known only at the ▷: @n for now
      var fr = frame();
      return ' data-act="' + esc(role + (op === "⊕" ? " ! " : " ? ") + l) + '" data-mc="' + (fr ? "@" + fr.n : "0") +
             '" data-side="' + (fr ? fr.side : "") + '"';
    }
    for (i = 0; i < toks.length; i++) {
      var k = toks[i], next = toks[i + 1];
      if (k.t === "w") {
        if (lab) { out += label(k.s); lab = false;
          if (next && next.t === "pay") { i++; if (next.s) out += '<span class="lt-pay">(' + esc(next.s) + ")</span>"; }
          out += "</span>"; }
        else if (next && next.t === "op") {
          var l2 = toks[i + 2];
          out += '<span class="lt-act"' + (l2 && l2.t === "w" ? at(k.s, next.s, l2.s) : "") + '><b class="lt-role">' + esc(k.s) + "</b>";
        }
        else if (k.s === "end") out += '<span class="lt-end">end</span>';
        else if (k.s === "rec" && next && next.t === "w") { out += '<span class="lt-kw">μ</span><i class="lt-var">' + esc(next.s) + "</i>"; i++; }
        else if (stack.length && !stack[stack.length - 1].mc && stack[stack.length - 1].head) {
          var ch = stack[stack.length - 1];
          out += '<span class="lt-act"' + at(ch.role, ch.op, k.s) + '>' + label(k.s);   // a branch's label
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
        if (stack.length && stack[stack.length - 1].mc) { stack[stack.length - 1].side = "r"; stack[stack.length - 1].id = k.n; }
        out += ' <span class="lt-op lt-mc" data-mc="' + esc(k.n) + '">▷' + (many ? "<sub>" + k.n + "</sub>" : "") + "</span> ";
      }
      else if (k.t === "[") {
        stack.push({ mc: true, side: "l", n: frames.length }); frames.push(stack[stack.length - 1]);
        if (i !== 0 || outer < 0) out += '<span class="lt-brk">[</span>';
      }
      else if (k.t === "]") { stack.pop(); if (i !== outer) out += '<span class="lt-brk">]</span>'; }
      else if (k.t === "{") {                                   // a choice: its role and ⊕ or & are just before
        stack.push({ mc: false, head: true, role: toks[i - 2] ? toks[i - 2].s : "", op: toks[i - 1] ? toks[i - 1].s : "" });
        out += '<span class="lt-brk">{</span> ';
      }
      else if (k.t === "}") { stack.pop(); out += ' <span class="lt-brk">}</span>'; }
      else if (k.t === ",") { if (stack.length && !stack[stack.length - 1].mc) stack[stack.length - 1].head = true; out += '<span class="lt-brk">,</span> '; }
      else if (k.t === "pay") { if (k.s) out += '<span class="lt-pay">(' + esc(k.s) + ")</span>"; }
      else out += esc(k.s);
    }
    return out.replace(/data-mc="@(\d+)"/g, function(_, n){ return 'data-mc="' + (frames[+n].id || "") + '"'; });
  };

  // Line numbers for an editor (div.lnum): a textarea over its highlighted <code>, as in
  // index.html. The highlight is redrawn after every change to the text, so each redraw
  // recounts; the textarea's scroll moves the numbers. A line marked in the highlight
  // (mark.eline, the lines at fault; mark.esoft, the construct) is marked here too. A click
  // selects the line.
  MMST.lineNumbers = function(ta, code){
    var box = ta.parentNode, g = document.createElement("div"), col = document.createElement("div"), last = "";
    g.className = "lnum";
    g.setAttribute("aria-hidden", "true");
    g.appendChild(col);
    box.insertBefore(g, box.firstChild);
    function move(){ col.style.transform = "translateY(" + -ta.scrollTop + "px)"; }
    function draw(){
      var lines = code.innerHTML.split("\n"), n = ta.value.split("\n").length, h = "";
      for (var i = 1; i <= n; i++) {
        var m = /<mark class="(eline|esoft)"/.exec(lines[i - 1] || "");
        h += (m ? '<span class="' + m[1] + '">' + i + "</span>" : i) + "\n";
      }
      if (h !== last) { col.innerHTML = h; last = h; }
      box.style.setProperty("--ln", Math.max(2, String(n).length) + "ch");
      move();
    }
    g.addEventListener("mousedown", function(e){
      var cs = getComputedStyle(ta), lh = parseFloat(cs.lineHeight) || 20;
      var line = Math.floor((e.clientY - g.getBoundingClientRect().top + ta.scrollTop - parseFloat(cs.paddingTop)) / lh);
      if (line < 0) return;
      var text = ta.value, start = 0;
      for (var i = 0; i < line; i++) { start = text.indexOf("\n", start) + 1; if (!start) return; }
      var end = text.indexOf("\n", start);
      e.preventDefault();
      ta.focus({ preventScroll: true });
      try { ta.setSelectionRange(start, end < 0 ? text.length : end); } catch (x) {}
    });
    ta.addEventListener("scroll", move);
    new MutationObserver(draw).observe(code, { childList: true });
    draw();
  };

  function each(list, f){ Array.prototype.forEach.call(list, f); }

  MMST.text = function(url){
    return fetch(url).then(function(r){
      if (!r.ok) throw new Error(url + ": HTTP " + r.status);
      return r.text();
    });
  };

  // [data-include="parts/x.html"]: the element's content becomes that file.
  MMST.include = function(root){
    var els = Array.prototype.slice.call(root.querySelectorAll("[data-include]"));
    return Promise.all(els.map(function(el){
      var url = el.getAttribute("data-include");
      el.removeAttribute("data-include");
      return MMST.text(url).then(function(html){ el.innerHTML = html; return MMST.include(el); });
    }));
  };

  // Code in el: ```scribble and ```erlang highlighted, ```types in the paper's notation, and
  // ```local, a local type a line as the checker prints it, shown as the playground shows it.
  // ✓ and ✗ are coloured in any code; `⊕`, `&`, `▷` in the text.
  MMST.code = function(el){
    each(el.querySelectorAll("pre > code"), function(c){
      var lang = /language-(scribble|erlang|types|local)/.exec(c.className);
      if (!lang) c.innerHTML = c.innerHTML.replace(/[✓✗]/g, function(x){ return '<span class="' + MARKS[x] + '">' + x + '</span>'; });
      else if (lang[1] === "types") c.innerHTML = MMST.highlightTypes(c.textContent);
      else if (lang[1] === "local") {
        c.parentNode.classList.add("lt");
        c.innerHTML = c.textContent.replace(/\s+$/, "").split("\n").map(MMST.localType).join("\n");
      }
      else c.innerHTML = MMST.highlight(c.textContent, lang[1]);
    });
    each(el.querySelectorAll(":not(pre) > code"), function(c){
      var cls = MARKS[c.textContent.trim()];
      if (cls) c.classList.add(cls);
    });
  };

  // Markdown into el, with marked (vendor/marked.umd.js). Additions:
  //   "{.lede} text"   a paragraph starting with classes gets them;
  //   "{.reading}"     a paragraph of classes alone gives them to the next element;
  //   code is coloured by MMST.code;
  //   on reading pages (opts.doc), # is the title, ## a section heading, ``` a code block.
  var MARK = /^\{((?:\s*\.[\w-]+)+)\s*\}\s*/;
  MMST.marks = function(el){
    each(el.querySelectorAll("p"), function(p){
      var m = MARK.exec(p.innerHTML);
      if (!m) return;
      var cls = m[1].trim().split(/\s+/).map(function(c){ return c.slice(1); });
      var rest = p.innerHTML.slice(m[0].length);
      if (rest.trim()) { p.innerHTML = rest; cls.forEach(function(c){ p.classList.add(c); }); return; }
      var next = p.nextElementSibling;
      if (next) cls.forEach(function(c){ next.classList.add(c); });
      p.parentNode.removeChild(p);
    });
  };
  MMST.md = function(el, src, opts){
    opts = opts || {};
    el.innerHTML = window.marked.parse(src);
    MMST.marks(el);
    MMST.code(el);
    if (opts.doc) {
      each(el.querySelectorAll("h1"), function(h){ h.classList.add("title"); });
      each(el.querySelectorAll("h2"), function(h){ h.classList.add("sec"); });
      each(el.querySelectorAll("pre"), function(p){ p.classList.add("code"); });
    }
    return MMST.include(el);
  };

  function header(){
    var h = document.getElementById("site-header");
    if (!h) return Promise.resolve();
    function shown(){ h.classList.add("ready"); }                // see theme.css: no jump while loading
    return MMST.text("header.html").then(function(html){
      var t = document.createElement("template");
      t.innerHTML = html;
      var slot = t.content.querySelector("[data-slot]");
      if (slot) {                                         // the page's own controls go here
        while (h.firstChild) slot.parentNode.insertBefore(h.firstChild, slot);
        slot.parentNode.removeChild(slot);
      }
      h.textContent = "";
      h.appendChild(t.content);
      var page = location.pathname.split("/").pop() || "index.html";
      each(h.querySelectorAll(".sub a"), function(a){
        if (a.getAttribute("href") === page) a.setAttribute("aria-current", "page");
      });
      var ed = h.querySelector("a[data-editor]");
      if (ed && page === "index.html") {                  // here, the button that hides and shows it (playground.js)
        var eb = document.createElement("button");
        eb.type = "button";
        eb.setAttribute("data-editor", "");
        eb.setAttribute("aria-pressed", "true");
        eb.title = "Hide the editor";
        eb.textContent = ed.textContent;
        ed.parentNode.replaceChild(eb, ed);
      }
      var b = h.querySelector("#theme");
      if (b) b.addEventListener("click", function(){
        var root = document.documentElement, cur = root.getAttribute("data-theme");
        var next = cur === "dark" ? "light" : cur === "light" ? "" : "dark";
        if (next) root.setAttribute("data-theme", next);
        else root.removeAttribute("data-theme");
        try { localStorage.setItem("mmst.theme", next); } catch (e) {}
      });
    }).then(shown, function(e){ shown(); throw e; });
  }

  function footer(){
    var f = document.getElementById("site-footer");
    if (!f) return Promise.resolve();
    return MMST.text("footer.html").then(function(html){ f.innerHTML = html; });
  }

  function markdown(){
    return Promise.all(Array.prototype.map.call(document.querySelectorAll("[data-md]"), function(el){
      var url = el.getAttribute("data-md");
      el.removeAttribute("data-md");
      return MMST.text(url).then(function(src){ return MMST.md(el, src, { doc: el.hasAttribute("data-doc") }); });
    }));
  }

  var settle;
  MMST.ready = new Promise(function(resolve){ settle = resolve; });
  document.addEventListener("DOMContentLoaded", function(){
    var parts = [header(), footer(), markdown(), MMST.include(document.body)].map(function(p){
      return p.catch(function(e){ if (window.console) console.error(e); });
    });
    Promise.all(parts).then(function(){ settle(); });
  });
})();

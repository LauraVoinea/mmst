// examples.html's script, in a file: the Content-Security-Policy runs no inline scripts.
(function(){
  "use strict";
  var E = window.MMST.examples, about = E.about;

  function $(id){ return document.getElementById(id); }
  function esc(s){ return String(s).replace(/[&<>"]/g, function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]; }); }
  function href(id, view){ return "./#ex=" + encodeURIComponent(id) + (view ? "&view=" + view : ""); }
  function slug(s){ return s.toLowerCase().replace(/[^a-z0-9]+/g, "-"); }

  var HEADINGS = {};

  // Roles, mixed choices, recursion; comments stripped (some hold old versions).
  function facts(src){
    var code = src.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/[^\n]*/g, ""), out = [];
    var roles = /global\s+protocol\s+\w+\s*\(([^)]*)\)/.exec(code);
    if (roles) out.push(roles[1].split(",").map(function(r){ return r.trim().replace(/^role\s+/, ""); }).join(", "));
    var mc = (code.match(/\bmixed\s*\{/g) || []).length;
    if (mc) out.push(mc + (mc === 1 ? " mixed choice" : " mixed choices"));
    if (/\brec\s+\w+/.test(code)) out.push("recursion");
    return out;
  }

  function card(x){
    var a = about[x.id] || {}, h = '<article class="ex" id="' + esc(x.id) + '">';
    h += '<div class="ex-head"><h2>' + esc(E.title(x.id)) + '</h2>' +
         (a.from ? '<span class="from">' + esc(a.from) + '</span>' : '') +
         '<span class="go"><a class="btn" href="' + href(x.id) + '" title="Check it">open</a>' +
         '<a class="btn" href="' + href(x.id, "efsm") + '" title="EFSM tab">efsm</a>' +
         (a.erlang ? '<a class="btn" href="./#mode=erlang&amp;erl=' +
                     encodeURIComponent(a.erlang.replace(/<[^>]*>/g, "").trim()) + '" title="Its Erlang">erlang</a>' : '') +
         '</span></div>';
    if (x.source) h += '<ul class="facts">' + facts(x.source).map(function(f){ return '<li>' + esc(f) + '</li>'; }).join("") + '</ul>';
    if (a.what) h += '<p>' + a.what + '</p>';
    if (a.mc) h += '<p><span class="lbl">mixed choice</span>' + a.mc + '</p>';
    if (a.look) h += '<p><span class="lbl">look</span>' + a.look + '</p>';
    if (a.tryIt) h += '<div class="try"><p><span class="lbl">try</span>' + a.tryIt[0] + '</p>' +
                      '<details><summary>result</summary><p>' + a.tryIt[1] + '</p></details></div>';
    if (x.source) h += '<details class="src"><summary>' + esc(x.path) + '</summary><pre class="code">' +
                       window.MMST.highlight(x.source, "scribble") + '</pre></details>';
    return h + '</article>';
  }

  function row(x){
    var a = about[x.id] || {};
    return '<li id="' + esc(x.id) + '"><span class="nm"><a href="' + href(x.id) + '" title="Check it">' +
           esc(E.title(x.id)) + '</a>' + (a.from ? '<span class="from">' + esc(a.from) + '</span>' : '') + '</span>' +
           '<span class="tx">' + (a.text || '') + '</span>' +
           '<a class="efsm" href="' + href(x.id, "efsm") + '" title="EFSM tab">efsm</a></li>';
  }

  function render(list, offline){
    var h = offline ? '<p class="note">Server offline: descriptions only.</p>' : '', nav = [];
    E.arrange(list, true).forEach(function(g){
      if (!g.items.length) return;
      var id = slug(g.group), name = HEADINGS[g.group] || g.group.toLowerCase();
      nav.push('<a href="#' + id + '">' + esc(name) + '</a>');
      h += '<section id="' + id + '"><h3 class="sec">' + esc(name) + '</h3>' +
           (E.groups[g.group] ? '<div class="intro">' + E.groups[g.group] + '</div>' : '') +
           (g.group === "Examples" ? g.items.map(card).join("")
                                   : '<ul class="rows">' + g.items.map(row).join("") + '</ul>') + '</section>';
    });
    $("groups").innerHTML = h;
    window.MMST.code($("groups"));                    // the introductions' ```local, `▷` and the like
    Array.prototype.forEach.call($("groups").querySelectorAll(".intro pre"), function(p){ p.classList.add("code"); });
    $("jump").innerHTML = nav.join("");
    // HTML parts in the introductions (Exercise 4's two runs), then the anchor: its lookup
    // ran before the content, so scroll again.
    function settle(){
      if (window.MMST.sides) window.MMST.sides($("groups"));
      var t = location.hash.length > 1 && document.getElementById(decodeURIComponent(location.hash.slice(1)));
      if (t) t.scrollIntoView();
    }
    window.MMST.include($("groups")).then(settle, settle);
  }

  // Offline: descriptions only, grouped as in text/examples.md.
  function fromAbout(){
    return Object.keys(about).map(function(id){
      return { id: id, group: about[id].group || "Examples", path: "", source: "" };
    });
  }

  var list = fetch("/api/examples")
    .then(function(r){ if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); });
  E.ready.then(function(){ return list; })
    .then(function(d){ render(d.examples || [], false); },
          function(){ render(fromAbout(), true); });
})();

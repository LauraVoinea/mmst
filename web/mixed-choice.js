// mixed-choice.html's script, in a file: the Content-Security-Policy runs no inline scripts.
// The four checks, from shared.js, with links to their definitions in the paper.
window.MMST.ready.then(function(){
  "use strict";
  var A = "https://arxiv.org/html/2602.23927v2#";
  function a(id, text){ return '<a href="' + A + id + '">' + text + "</a>"; }
  var AWARE = "<b>awareness</b>: " + a("S3.Thmtheorem9", "Definition 3.9") + ", " + a("S3.SS3", "§3.3");
  var REFS = {
    WF: a("S3.Thmtheorem4", "Definition 3.4") + ", " + a("S3.SS1", "§3.1"),
    SD: "with CT, " + AWARE,
    CT: "with SD, " + AWARE,
    BA: a("S3.Thmtheorem12", "Definition 3.12") + ", " + a("S3.SS3", "§3.3")
  };
  var slot = document.querySelector(".checks"), C = window.MMST.checks, h = "<dl>";
  if (!slot) return;
  window.MMST.order.forEach(function(k){
    h += "<dt>" + k + "<span>" + C[k][0] + "</span></dt><dd>" + C[k][1].replace(/\.$/, "") + " (" + REFS[k] + ").</dd>";
  });
  slot.innerHTML = h + "</dl>";
});

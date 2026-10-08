/* John Foods landing interactions. Vanilla JS, no dependencies. */
(function () {
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  var nav = document.getElementById("nav");
  var progress = document.getElementById("progress");
  var toTop = document.getElementById("toTop");

  function onScroll() {
    var y = window.scrollY;
    nav.classList.toggle("scrolled", y > 8);
    if (toTop) toTop.classList.toggle("show", y > 600);
    if (progress) {
      var h = document.documentElement.scrollHeight - window.innerHeight;
      var p = h > 0 ? (y / h) * 100 : 0;
      progress.style.width = p + "%";
    }
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
  if (toTop) toTop.addEventListener("click", function () {
    window.scrollTo({ top: 0, behavior: reduceMotion ? "auto" : "smooth" });
  });

  /* Mobile drawer */
  var burger = document.getElementById("burger");
  var drawer = document.getElementById("drawer");
  burger.addEventListener("click", function () {
    var open = drawer.classList.toggle("open");
    burger.setAttribute("aria-expanded", open ? "true" : "false");
    burger.querySelector(".material-symbols-rounded").textContent = open ? "close" : "menu";
  });
  drawer.querySelectorAll("a").forEach(function (a) {
    a.addEventListener("click", function () {
      drawer.classList.remove("open");
      burger.setAttribute("aria-expanded", "false");
      burger.querySelector(".material-symbols-rounded").textContent = "menu";
    });
  });

  /* Scroll spy */
  var links = Array.prototype.slice.call(document.querySelectorAll(".links a"));
  var sections = links.map(function (a) {
    return document.querySelector(a.getAttribute("href"));
  });
  function spy() {
    var y = window.scrollY + 140;
    var current = sections[0] && sections[0].id;
    sections.forEach(function (s) {
      if (s && s.offsetTop <= y) current = s.id;
    });
    links.forEach(function (a) {
      a.classList.toggle("active", a.getAttribute("href") === "#" + current);
    });
  }
  window.addEventListener("scroll", spy, { passive: true });
  spy();

  /* Reveal on scroll with stagger */
  var revealEls = document.querySelectorAll(".reveal");
  revealEls.forEach(function (el) {
    var d = el.getAttribute("data-delay");
    if (d) el.style.transitionDelay = d + "ms";
  });
  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealEls.forEach(function (el) { el.classList.add("in"); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.classList.add("in");
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
    revealEls.forEach(function (el) { io.observe(el); });
  }

  /* Count up stats */
  function countUp(el) {
    var target = parseInt(el.getAttribute("data-count"), 10);
    if (isNaN(target)) return;
    if (reduceMotion) { el.textContent = String(target); return; }
    var start = 0;
    var dur = 1100;
    var t0 = null;
    function tick(t) {
      if (!t0) t0 = t;
      var p = Math.min((t - t0) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = String(Math.round(start + (target - start) * eased));
      if (p < 1) requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }
  var counters = document.querySelectorAll("[data-count]");
  if ("IntersectionObserver" in window && !reduceMotion) {
    var cio = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          countUp(e.target);
          cio.unobserve(e.target);
        }
      });
    }, { threshold: 0.6 });
    counters.forEach(function (c) { cio.observe(c); });
  }

  /* Phone 3D tilt */
  var tilt = document.getElementById("phoneTilt");
  if (tilt && !reduceMotion && window.matchMedia("(pointer: fine)").matches) {
    var wrap = tilt.parentElement;
    wrap.addEventListener("mousemove", function (e) {
      var r = wrap.getBoundingClientRect();
      var x = (e.clientX - r.left) / r.width - 0.5;
      var y = (e.clientY - r.top) / r.height - 0.5;
      tilt.style.transform = "rotateY(" + (x * 12) + "deg) rotateX(" + (-y * 10) + "deg)";
    });
    wrap.addEventListener("mouseleave", function () {
      tilt.style.transform = "rotateY(0deg) rotateX(0deg)";
    });
  }

  /* Subtle magnetic buttons */
  if (!reduceMotion && window.matchMedia("(pointer: fine)").matches) {
    document.querySelectorAll(".magnetic").forEach(function (btn) {
      btn.addEventListener("mousemove", function (e) {
        var r = btn.getBoundingClientRect();
        var x = e.clientX - r.left - r.width / 2;
        var y = e.clientY - r.top - r.height / 2;
        btn.style.transform = "translate(" + (x * 0.08) + "px," + (y * 0.08) + "px)";
      });
      btn.addEventListener("mouseleave", function () {
        btn.style.transform = "";
      });
    });
  }

  /* Menu chips and grid with entrance animation */
  var chipsEl = document.getElementById("chips");
  var gridEl = document.getElementById("grid");
  var countEl = document.getElementById("dishCount");
  var activeCat = "all";

  function renderChips() {
    var all = [{ id: "all", name: "All" }].concat(CATEGORIES);
    chipsEl.innerHTML = "";
    all.forEach(function (c) {
      var b = document.createElement("button");
      b.textContent = c.name;
      b.setAttribute("role", "tab");
      b.setAttribute("aria-selected", c.id === activeCat ? "true" : "false");
      b.className = c.id === activeCat ? "on" : "";
      b.addEventListener("click", function () {
        if (activeCat === c.id) return;
        activeCat = c.id;
        renderChips();
        renderGrid();
      });
      chipsEl.appendChild(b);
    });
  }

  function renderGrid() {
    gridEl.innerHTML = "";
    var list = FOODS.filter(function (f) {
      return activeCat === "all" || f.cat === activeCat;
    });
    if (countEl) countEl.textContent = list.length + (list.length === 1 ? " dish" : " dishes");
    list.forEach(function (f, i) {
      var card = document.createElement("article");
      card.className = "dish";
      card.style.animationDelay = reduceMotion ? "0ms" : Math.min(i * 35, 400) + "ms";
      card.innerHTML =
        '<div class="ph"><img loading="lazy" width="800" height="600" alt=""><span class="rate"><span class="material-symbols-rounded">star</span></span></div>' +
        '<div class="info"><strong></strong><span class="time"></span><span class="price"></span></div>';
      var img = card.querySelector("img");
      img.src = f.img;
      img.alt = f.name;
      card.querySelector(".rate").append(document.createTextNode(f.rating.toFixed(1)));
      card.querySelector("strong").textContent = f.name;
      card.querySelector(".time").textContent = f.time;
      card.querySelector(".price").textContent = peso(f.price);
      gridEl.appendChild(card);
    });
  }

  renderChips();
  renderGrid();

  /* Contact form via mailto. Static page, no backend. */
  var form = document.getElementById("contactForm");
  var note = document.getElementById("formNote");
  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var fd = new FormData(e.target);
    var name = (fd.get("name") || "").toString().trim();
    var email = (fd.get("email") || "").toString().trim();
    var msg = (fd.get("message") || "").toString().trim();
    if (!name || !email || !msg) {
      if (note) note.textContent = "Please complete all fields so we can reply.";
      return;
    }
    var subject = encodeURIComponent("John Foods inquiry from " + name);
    var body = encodeURIComponent(msg + "\n\nFrom " + name + " (" + email + ")");
    if (note) note.textContent = "Opening your email app to send the message...";
    window.location.href = "mailto:merjohnpagente7@gmail.com?subject=" + subject + "&body=" + body;
  });
})();

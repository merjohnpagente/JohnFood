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

  /* Organized menu: search plus grouped categories plus counts */
  var chipsEl = document.getElementById("chips");
  var gridEl = document.getElementById("grid");
  var countEl = document.getElementById("dishCount");
  var noteEl = document.getElementById("menuNote");
  var searchEl = document.getElementById("menuSearch");
  var clearEl = document.getElementById("clearSearch");
  var activeCat = "all";
  var query = "";
  var GROUP_PREVIEW = 4;

  var CAT_ICONS = {
    all: "restaurant_menu",
    burgers: "lunch_dining",
    pizza: "local_pizza",
    chicken: "dinner_dining",
    rice: "rice_bowl",
    pasta: "ramen_dining",
    drinks: "local_drink",
    desserts: "icecream",
    snacks: "cookie"
  };

  function catName(id) {
    if (id === "all") return "All dishes";
    for (var i = 0; i < CATEGORIES.length; i++) {
      if (CATEGORIES[i].id === id) return CATEGORIES[i].name;
    }
    return "Menu";
  }

  function catCount(id) {
    if (id === "all") return FOODS.length;
    return FOODS.filter(function (f) { return f.cat === id; }).length;
  }

  function setCat(id) {
    if (activeCat === id) return;
    activeCat = id;
    renderChips();
    renderGrid();
  }

  function renderChips() {
    var all = [{ id: "all", name: "All" }].concat(CATEGORIES);
    chipsEl.innerHTML = "";
    all.forEach(function (c) {
      var b = document.createElement("button");
      b.setAttribute("role", "tab");
      b.setAttribute("aria-selected", c.id === activeCat ? "true" : "false");
      b.className = c.id === activeCat ? "on" : "";
      var label = document.createElement("span");
      label.textContent = c.name;
      var n = document.createElement("span");
      n.className = "chip-n";
      n.textContent = String(catCount(c.id));
      b.appendChild(label);
      b.appendChild(n);
      b.addEventListener("click", function () { setCat(c.id); });
      chipsEl.appendChild(b);
    });
  }

  function makeDish(f, i) {
    var card = document.createElement("article");
    card.className = "dish";
    card.style.animationDelay = reduceMotion ? "0ms" : Math.min(i * 35, 400) + "ms";
    card.innerHTML =
      '<div class="ph"><img loading="lazy" width="800" height="600" alt=""><span class="rate"><span class="material-symbols-rounded">star</span></span></div>' +
      '<div class="info"><strong></strong><div class="info-row"><span class="price"></span><span class="time"></span></div></div>';
    var img = card.querySelector("img");
    img.src = f.img;
    img.alt = f.name;
    card.querySelector(".rate").append(document.createTextNode(f.rating.toFixed(1)));
    card.querySelector("strong").textContent = f.name;
    card.querySelector(".time").textContent = f.time;
    card.querySelector(".price").textContent = peso(f.price);
    return card;
  }

  function matchesQuery(f) {
    if (!query) return true;
    return f.name.toLowerCase().indexOf(query) !== -1;
  }

  function renderGrid() {
    gridEl.innerHTML = "";
    var grouped = activeCat === "all" && !query;
    gridEl.classList.toggle("grouped", grouped);

    if (grouped) {
      if (countEl) countEl.textContent = FOODS.length + " dishes";
      if (noteEl) noteEl.textContent = "Top picks per category. Open a category to see everything.";
      CATEGORIES.forEach(function (c) {
        var items = FOODS.filter(function (f) { return f.cat === c.id; });
        if (!items.length) return;
        var group = document.createElement("section");
        group.className = "menu-group";
        group.innerHTML =
          '<header class="group-head"><span class="group-icon"><span class="material-symbols-rounded"></span></span>' +
          '<div class="group-title"><h3></h3><span class="muted"></span></div>' +
          '<button class="view-all" type="button">View all<span class="material-symbols-rounded">arrow_forward</span></button></header>' +
          '<div class="grid"></div>';
        group.querySelector(".group-icon .material-symbols-rounded").textContent = CAT_ICONS[c.id] || "fastfood";
        group.querySelector("h3").textContent = c.name;
        group.querySelector(".group-title .muted").textContent = items.length + (items.length === 1 ? " dish" : " dishes");
        var btn = group.querySelector(".view-all");
        btn.setAttribute("data-viewall", c.id);
        btn.setAttribute("aria-label", "View all " + c.name);
        var inner = group.querySelector(".grid");
        items.slice(0, GROUP_PREVIEW).forEach(function (f, i) {
          inner.appendChild(makeDish(f, i));
        });
        gridEl.appendChild(group);
      });
      return;
    }

    var list = FOODS.filter(function (f) {
      return (activeCat === "all" || f.cat === activeCat) && matchesQuery(f);
    });
    if (countEl) countEl.textContent = list.length + (list.length === 1 ? " dish" : " dishes");
    if (query) {
      if (noteEl) noteEl.textContent = list.length + (list.length === 1 ? " result" : " results") + ' for "' + query + '"';
    } else if (noteEl) {
      noteEl.textContent = catName(activeCat) + " in full. Pick another tab to browse more.";
    }
    if (!list.length) {
      var empty = document.createElement("div");
      empty.className = "empty";
      empty.innerHTML =
        '<span class="material-symbols-rounded">search_off</span>' +
        "<p></p>" +
        '<button class="btn btn-outline btn-sm" type="button">Clear search</button>';
      empty.querySelector("p").textContent = 'No dishes match "' + query + '". Try pizza, burger or halo halo.';
      empty.querySelector("button").addEventListener("click", resetMenu);
      gridEl.appendChild(empty);
      return;
    }
    var flat = document.createElement("div");
    flat.className = "grid";
    list.forEach(function (f, i) {
      flat.appendChild(makeDish(f, i));
    });
    gridEl.appendChild(flat);
  }

  function resetMenu() {
    query = "";
    if (searchEl) searchEl.value = "";
    if (clearEl) clearEl.hidden = true;
    setCat("all");
    renderGrid();
  }

  gridEl.addEventListener("click", function (e) {
    var t = e.target.closest("[data-viewall]");
    if (t) {
      setCat(t.getAttribute("data-viewall"));
      document.getElementById("menu").scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth" });
    }
  });

  var searchTimer = null;
  if (searchEl) {
    searchEl.addEventListener("input", function () {
      if (clearEl) clearEl.hidden = !searchEl.value;
      clearTimeout(searchTimer);
      searchTimer = setTimeout(function () {
        query = searchEl.value.trim().toLowerCase();
        if (query && activeCat !== "all") {
          activeCat = "all";
          renderChips();
        }
        renderGrid();
      }, 150);
    });
  }
  if (clearEl) {
    clearEl.addEventListener("click", function () {
      query = "";
      searchEl.value = "";
      clearEl.hidden = true;
      searchEl.focus();
      renderGrid();
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

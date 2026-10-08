/* John Foods landing interactions. Vanilla JS, no dependencies. */
(function () {
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* Header shadow */
  var nav = document.getElementById("nav");
  function onScroll() {
    nav.classList.toggle("scrolled", window.scrollY > 8);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

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

  /* Scroll-spy */
  var links = Array.prototype.slice.call(document.querySelectorAll(".links a"));
  var sections = links.map(function (a) {
    return document.querySelector(a.getAttribute("href"));
  });
  function spy() {
    var y = window.scrollY + 120;
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

  /* Reveal on scroll */
  var revealEls = document.querySelectorAll(".reveal");
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
    }, { threshold: 0.12 });
    revealEls.forEach(function (el) { io.observe(el); });
  }

  /* Menu: chips + grid */
  var chipsEl = document.getElementById("chips");
  var gridEl = document.getElementById("grid");
  var activeCat = "all";

  function renderChips() {
    var all = [{ id: "all", name: "All" }].concat(CATEGORIES);
    chipsEl.innerHTML = "";
    all.forEach(function (c) {
      var b = document.createElement("button");
      b.textContent = c.name;
      b.setAttribute("role", "tab");
      b.className = c.id === activeCat ? "on" : "";
      b.addEventListener("click", function () {
        activeCat = c.id;
        renderChips();
        renderGrid();
      });
      chipsEl.appendChild(b);
    });
  }

  function renderGrid() {
    gridEl.innerHTML = "";
    FOODS.filter(function (f) {
      return activeCat === "all" || f.cat === activeCat;
    }).forEach(function (f) {
      var card = document.createElement("article");
      card.className = "dish";
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

  /* Contact form via mailto (static page, no backend) */
  document.getElementById("contactForm").addEventListener("submit", function (e) {
    e.preventDefault();
    var fd = new FormData(e.target);
    var subject = encodeURIComponent("John Foods inquiry from " + fd.get("name"));
    var body = encodeURIComponent(fd.get("message") + "\n\n— " + fd.get("name") + " (" + fd.get("email") + ")");
    window.location.href = "mailto:merjohnpagente7@gmail.com?subject=" + subject + "&body=" + body;
  });
})();

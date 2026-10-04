(() => {
  "use strict";

  const root = document.documentElement;

  // Keep the footer copyright current. The markup carries a year so the page
  // still reads correctly with JavaScript off.
  const year = String(new Date().getFullYear());
  for (const el of document.querySelectorAll("[data-year]")) {
    el.textContent = year;
  }

  /* ---------------------------------------------------------------------
     Appearance: color scheme + accent

     Both live on <html> as data attributes, and an inline script in the
     document head has already applied the saved values before first paint.
     Everything here is the interactive half: reacting to the menu, keeping
     "system" live while the tab is open, and writing choices back.

       data-theme   "vbv" | "vbv-dark"   — the daisyUI palette
       data-accent  one of ACCENTS       — which brand color that palette uses

     theme-mode is stored separately from data-theme because "system" is a
     third state that the attribute itself cannot express.
     --------------------------------------------------------------------- */

  const ACCENTS = ["violet", "ocean", "forest", "sunset", "blush", "slate", "twilight"];
  const MODES = ["system", "light", "dark"];

  const darkMq = window.matchMedia("(prefers-color-scheme: dark)");
  const modeButtons = document.querySelectorAll("[data-theme-mode]");
  const accentButtons = document.querySelectorAll(".accent-swatch[data-accent]");

  const read = (key, fallback, allowed) => {
    let value = null;
    try {
      value = localStorage.getItem(key);
    } catch (e) {
      // Storage disabled (private mode, etc.) — the default still applies.
    }
    return allowed.includes(value) ? value : fallback;
  };

  const write = (key, value) => {
    try {
      localStorage.setItem(key, value);
    } catch (e) {
      // The choice still applies to this page, it just will not persist.
    }
  };

  const applyMode = (mode) => {
    const dark = mode === "dark" || (mode === "system" && darkMq.matches);
    root.dataset.theme = dark ? "vbv-dark" : "vbv";
    for (const btn of modeButtons) {
      const selected = btn.dataset.themeMode === mode;
      btn.classList.toggle("menu-active", selected);
      btn.setAttribute("aria-pressed", String(selected));
    }
  };

  const applyAccent = (accent) => {
    root.dataset.accent = accent;
    for (const btn of accentButtons) {
      btn.setAttribute("aria-checked", String(btn.dataset.accent === accent));
    }
  };

  applyMode(read("theme-mode", "system", MODES));
  applyAccent(read("theme-accent", "violet", ACCENTS));

  // A <details> dropdown stays open after a click inside it, which leaves the
  // menu covering the page you just recolored.
  const closeMenu = (el) => el.closest("details")?.removeAttribute("open");

  for (const btn of modeButtons) {
    btn.addEventListener("click", () => {
      write("theme-mode", btn.dataset.themeMode);
      applyMode(btn.dataset.themeMode);
      closeMenu(btn);
    });
  }

  // The accent swatches stay put on click: picking a color is the one choice
  // worth seeing take effect before the menu goes away.
  for (const btn of accentButtons) {
    btn.addEventListener("click", () => {
      write("theme-accent", btn.dataset.accent);
      applyAccent(btn.dataset.accent);
    });
  }

  darkMq.addEventListener("change", () => {
    if (read("theme-mode", "system", MODES) === "system") applyMode("system");
  });

  // Close the appearance menu on Escape or on a click outside it.
  const menu = document.querySelector("details.dropdown");
  if (menu) {
    document.addEventListener("click", (event) => {
      if (menu.open && !menu.contains(event.target)) menu.removeAttribute("open");
    });
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && menu.open) {
        menu.removeAttribute("open");
        menu.querySelector("summary")?.focus();
      }
    });
  }

  /* ---------------------------------------------------------------------
     Sections fade up once as they scroll into view.

     The CSS that hides them is gated on `.js-reveal`, which is added here, so
     a visitor without JavaScript gets the page fully visible rather than a
     blank one. Reduced motion is handled in the stylesheet.

     This reveals anything whose top has risen above the trigger line, rather
     than anything currently on screen. An IntersectionObserver would be the
     obvious tool and is the wrong one: jump straight to the footer, or follow
     an anchor, and a section can travel from below the viewport to above it
     between two samples without ever intersecting, so it never fires and that
     section stays invisible for the rest of the visit. Comparing against the
     line cannot miss, and with a handful of sections the sweep is cheaper than
     the observer it replaces.
     --------------------------------------------------------------------- */

  const pending = [...document.querySelectorAll(".reveal")];
  if (pending.length) {
    root.classList.add("js-reveal");

    let queued = false;

    const sweep = () => {
      queued = false;
      const line = window.innerHeight * 0.88;
      for (let i = pending.length - 1; i >= 0; i--) {
        if (pending[i].getBoundingClientRect().top >= line) continue;
        pending[i].classList.add("is-in");
        pending.splice(i, 1);
      }
      if (!pending.length) {
        window.removeEventListener("scroll", schedule);
        window.removeEventListener("resize", schedule);
      }
    };

    const schedule = () => {
      if (queued) return;
      queued = true;
      requestAnimationFrame(sweep);
    };

    window.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", schedule);
    sweep();
  }
})();

(() => {
  "use strict";

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const gsapReady = typeof window.gsap !== "undefined" && typeof window.ScrollTrigger !== "undefined";

  document.querySelectorAll("[data-year]").forEach((node) => {
    node.textContent = String(new Date().getFullYear());
  });

  document.querySelectorAll("video[autoplay]").forEach((video) => {
    video.muted = true;
    video.defaultMuted = true;
    const resume = () => {
      if (video.paused) video.play().catch(() => {});
    };
    if (video.readyState >= 2) resume();
    else video.addEventListener("canplay", resume, { once: true });
  });

  const progressBar = document.querySelector("[data-scroll-progress]");
  const updateNativeProgress = () => {
    if (!progressBar) return;
    const available = document.documentElement.scrollHeight - window.innerHeight;
    const progress = available > 0 ? window.scrollY / available : 0;
    progressBar.style.transform = `scaleY(${Math.min(1, Math.max(0, progress))})`;
  };

  if (!gsapReady || reducedMotion) {
    document.querySelectorAll("[data-reveal]").forEach((node) => {
      node.style.opacity = "1";
      node.style.transform = "none";
    });
    document.querySelectorAll(".heart-statements > *, .gps-label.restored, .route-point, .morph-path, .story-path").forEach((node) => {
      node.style.opacity = "1";
    });
    window.addEventListener("scroll", updateNativeProgress, { passive: true });
    updateNativeProgress();
    return;
  }

  const { gsap, ScrollTrigger } = window;
  gsap.registerPlugin(ScrollTrigger);

  if (typeof window.Lenis !== "undefined") {
    const lenis = new window.Lenis({
      duration: 1.05,
      smoothWheel: true,
      wheelMultiplier: 0.86,
      touchMultiplier: 1.05,
      anchors: { offset: 0 }
    });
    lenis.on("scroll", ScrollTrigger.update);
    gsap.ticker.add((time) => lenis.raf(time * 1000));
    gsap.ticker.lagSmoothing(0);
  }

  gsap.to(progressBar, {
    scaleY: 1,
    ease: "none",
    scrollTrigger: { trigger: document.documentElement, start: "top top", end: "bottom bottom", scrub: 0.15 }
  });

  gsap.from("[data-hero-line]", {
    yPercent: 48,
    opacity: 0,
    duration: 1.15,
    stagger: 0.13,
    ease: "power3.out",
    delay: 0.16
  });
  gsap.from("[data-hero-detail]", {
    y: 18,
    opacity: 0,
    duration: 0.8,
    stagger: 0.1,
    ease: "power2.out",
    delay: 0.58
  });
  gsap.to("#scene-01 .run-media video", {
    scale: 1.055,
    yPercent: 2,
    ease: "none",
    scrollTrigger: { trigger: "#scene-01", start: "top top", end: "bottom top", scrub: true }
  });

  gsap.utils.toArray("[data-reveal]").forEach((node) => {
    if (node.closest("#scene-01")) return;
    gsap.from(node, {
      y: 34,
      opacity: 0,
      duration: 0.82,
      ease: "power2.out",
      scrollTrigger: { trigger: node, start: "top 86%", once: true }
    });
  });

  const drawPath = (selector) => {
    const path = document.querySelector(selector);
    if (!path || typeof path.getTotalLength !== "function") return null;
    const length = path.getTotalLength();
    gsap.set(path, { strokeDasharray: length, strokeDashoffset: length });
    return { path, length };
  };

  const problemPaths = gsap.utils.toArray(".problem-track");
  problemPaths.forEach((path) => {
    const length = path.getTotalLength();
    gsap.set(path, { strokeDasharray: path.classList.contains("ghost") ? "9 12" : length, strokeDashoffset: path.classList.contains("ghost") ? 0 : length });
  });
  gsap.to(".problem-track:not(.ghost)", {
    strokeDashoffset: 0,
    ease: "none",
    scrollTrigger: { trigger: "#scene-02", start: "top 50%", end: "65% 55%", scrub: true }
  });
  gsap.fromTo(".problem-track.ghost", { opacity: 0.5 }, {
    opacity: 0.04,
    ease: "none",
    scrollTrigger: { trigger: "#scene-02", start: "35% 50%", end: "bottom 45%", scrub: true }
  });
  gsap.fromTo(".disconnect-mark", { scale: 0.75, opacity: 0 }, {
    scale: 1,
    opacity: 1,
    scrollTrigger: { trigger: "#scene-02", start: "38% 55%", end: "56% 55%", scrub: true }
  });

  const recovery = drawPath("[data-recovery-path]");
  if (recovery) {
    const recoveryTimeline = gsap.timeline({
      scrollTrigger: { trigger: "#scene-04", start: "top top", end: "bottom bottom", scrub: true }
    });
    recoveryTimeline
      .to(recovery.path, { strokeDashoffset: recovery.length * 0.48, ease: "none", duration: 0.42 })
      .to(".gps-label.lost", { opacity: 1, scale: 1.05, duration: 0.12 }, 0.31)
      .to(".gps-label.lost", { opacity: 0.32, duration: 0.13 }, 0.52)
      .to(recovery.path, { strokeDashoffset: 0, ease: "none", duration: 0.42 }, 0.48)
      .to(".gps-label.restored", { opacity: 1, duration: 0.14 }, 0.6)
      .to(".route-point", { opacity: 1, scale: 1.12, duration: 0.14 }, 0.63);
  }

  const heart = drawPath("[data-heart-path]");
  if (heart) {
    const heartTimeline = gsap.timeline({
      scrollTrigger: { trigger: "#scene-05", start: "top top", end: "bottom bottom", scrub: true }
    });
    heartTimeline
      .to("#scene-05 .run-media video", { scale: 1.07, yPercent: 2, duration: 1, ease: "none" }, 0)
      .to(heart.path, { strokeDashoffset: 0, duration: 0.45, ease: "none" }, 0.2)
      .to(".heart-copy", { yPercent: -9, opacity: 0.36, duration: 0.34 }, 0.44)
      .to(".heart-statements p:nth-child(1)", { opacity: 1, y: -4, duration: 0.12 }, 0.45)
      .to(".heart-statements p:nth-child(2)", { opacity: 1, y: -4, duration: 0.12 }, 0.59)
      .to(".heart-statements strong", { opacity: 1, y: -4, duration: 0.17 }, 0.72);
  }

  const morphRoute = drawPath("[data-morph-route]");
  const morphPulse = drawPath("[data-morph-pulse]");
  const morphVessel = drawPath("[data-morph-vessel]");
  if (morphRoute && morphPulse && morphVessel) {
    gsap.set(morphPulse.path, { opacity: 0 });
    gsap.set(morphVessel.path, { opacity: 0 });
    const morphTimeline = gsap.timeline({
      scrollTrigger: { trigger: "#scene-07", start: "top top", end: "bottom bottom", scrub: true }
    });
    morphTimeline
      .to(morphRoute.path, { strokeDashoffset: 0, duration: 0.24, ease: "none" })
      .to(morphRoute.path, { opacity: 0.08, duration: 0.14 })
      .to(morphPulse.path, { opacity: 1, strokeDashoffset: 0, duration: 0.22, ease: "none" }, "<")
      .to(morphPulse.path, { opacity: 0.08, duration: 0.14 })
      .to(morphVessel.path, { opacity: 1, strokeDashoffset: 0, duration: 0.26, ease: "none" }, "<");
  }

  const storyPaths = gsap.utils.toArray("[data-story-path]");
  storyPaths.forEach((path, index) => {
    const length = path.getTotalLength();
    gsap.set(path, { strokeDasharray: length, strokeDashoffset: index === 0 ? length : 0, opacity: index === 0 ? 1 : 0 });
  });
  const motionSteps = gsap.utils.toArray(".motion-steps li");
  const setStep = (index) => motionSteps.forEach((step, stepIndex) => step.classList.toggle("is-active", stepIndex === index));
  const storyTimeline = gsap.timeline({
    scrollTrigger: {
      trigger: "#scene-15",
      start: "top top",
      end: "bottom bottom",
      scrub: true,
      onUpdate: ({ progress }) => setStep(Math.min(3, Math.floor(progress * 4)))
    }
  });
  storyTimeline
    .to(storyPaths[0], { strokeDashoffset: 0, duration: 0.25, ease: "none" })
    .to(storyPaths[0], { opacity: 0.1, duration: 0.12 })
    .to(storyPaths[1], { opacity: 1, duration: 0.18 }, "<")
    .to(storyPaths[1], { opacity: 0.1, duration: 0.12 })
    .to(storyPaths[2], { opacity: 1, duration: 0.2 }, "<");

  gsap.from(".integrity-line b", {
    scaleX: 0,
    stagger: 0.12,
    duration: 0.6,
    ease: "power2.out",
    scrollTrigger: { trigger: ".integrity-line", start: "top 82%", once: true }
  });

  ScrollTrigger.refresh();
})();

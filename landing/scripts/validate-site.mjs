import { existsSync, readFileSync, statSync } from "node:fs";
import { createHash } from "node:crypto";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const htmlPath = resolve(root, "index.html");
const html = readFileSync(htmlPath, "utf8");
const errors = [];

const sceneIds = [...html.matchAll(/data-scene="(\d{2})"/g)].map((match) => match[1]);
const expectedScenes = Array.from({ length: 18 }, (_, index) => String(index + 1).padStart(2, "0"));
if (JSON.stringify(sceneIds) !== JSON.stringify(expectedScenes)) {
  errors.push(`Scene order mismatch: ${sceneIds.join(", ")}`);
}

const localReferences = [...html.matchAll(/(?:src|href)="([^"]+)"/g)]
  .map((match) => match[1])
  .filter((reference) => !/^(?:https?:|mailto:|#)/.test(reference));

for (const reference of new Set(localReferences)) {
  const filePath = resolve(root, reference.split(/[?#]/)[0]);
  if (!existsSync(filePath) || !statSync(filePath).isFile()) {
    errors.push(`Missing local asset: ${reference}`);
  }
}

const runningVideo = "assets/media/balmi-dawn-run.mp4";
const videoUses = [...html.matchAll(new RegExp(`<source src="${runningVideo.replaceAll(".", "\\.")}"`, "g"))].length;
if (videoUses !== 2) errors.push(`Running video must be reused exactly twice; found ${videoUses}`);

const requiredMetadata = [
  "rel=\"canonical\"",
  "property=\"og:image\"",
  "name=\"twitter:card\"",
  "application/ld+json"
];
for (const metadata of requiredMetadata) {
  if (!html.includes(metadata)) errors.push(`Missing metadata: ${metadata}`);
}

const og = readFileSync(resolve(root, "assets/og-balmi.png"));
const width = og.readUInt32BE(16);
const height = og.readUInt32BE(20);
if (width !== 1200 || height !== 630) errors.push(`OG image must be 1200x630; found ${width}x${height}`);

const deployRoot = resolve(root, "../docs");
const mirroredFiles = [
  "index.html",
  "story.css",
  "story.js",
  "assets/balmi-app-icon.png",
  "assets/og-balmi.png",
  "assets/media/balmi-dawn-run.mp4",
  "assets/vendor/gsap.min.js",
  "assets/vendor/ScrollTrigger.min.js",
  "assets/vendor/lenis.min.js"
];
const digest = (path) => createHash("sha256").update(readFileSync(path)).digest("hex");
for (const relativePath of mirroredFiles) {
  const source = resolve(root, relativePath);
  const deployed = resolve(deployRoot, relativePath);
  if (!existsSync(deployed)) errors.push(`Missing deployment mirror: docs/${relativePath}`);
  else if (digest(source) !== digest(deployed)) errors.push(`Deployment mirror differs: docs/${relativePath}`);
}

if (errors.length) {
  console.error("Balmi landing validation failed:\n- " + errors.join("\n- "));
  process.exit(1);
}

console.log(`Balmi landing validation passed: ${sceneIds.length} scenes, ${new Set(localReferences).size} local assets, OG ${width}x${height}, docs mirror verified.`);

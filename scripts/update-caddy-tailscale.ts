#!/usr/bin/env bun
// Bumps the caddy-tailscale plugin pseudo-version + content hash to the
// latest commit on master, then commits the change. If nothing changed,
// exits silently. Mirrors the original bash recipe.
//
// Two-step build dance:
//   1. Update the version, try to build with the current hash.
//   2. If nix rejects the hash, blank it out, build again to capture
//      the correct hash from nix's "got: sha256-..." error, write it back.

import { $ } from "bun";

const CADDY_FILE = "nix/nixos/services/caddy.nix";
const GITHUB_REPO = "tailscale/caddy-tailscale";
const NIX_BUILD_TARGET =
  ".#nixosConfigurations.jubilife.config.services.caddy.package";

type GithubCommit = {
  sha: string;
  commit: { committer: { date: string } };
};

async function fetchLatestVersion(): Promise<string> {
  const url = `https://api.github.com/repos/${GITHUB_REPO}/commits?per_page=1`;
  const response = await fetch(url);
  if (!response.ok) {
    console.error(`github api: ${response.status} ${response.statusText}`);
    process.exit(1);
  }
  const [latestCommit] = (await response.json()) as GithubCommit[];
  const shortSha = latestCommit.sha.slice(0, 12);
  // YYYY-MM-DDTHH:MM:SSZ → YYYYMMDDHHMMSS, the Go pseudo-version style.
  const timestamp = latestCommit.commit.committer.date.replaceAll(
    /[-T:Z]/g,
    "",
  );
  return `v0.0.0-${timestamp}-${shortSha}`;
}

async function readCaddyNix(): Promise<string> {
  return Bun.file(CADDY_FILE).text();
}

async function writeCaddyNix(contents: string): Promise<void> {
  await Bun.write(CADDY_FILE, contents);
}

function currentVersionIn(caddyNix: string): string {
  const match = caddyNix.match(/caddy-tailscale@([^"]+)/);
  if (!match) {
    console.error(`could not find caddy-tailscale version in ${CADDY_FILE}`);
    process.exit(1);
  }
  return match[1];
}

async function tryBuild(): Promise<{ ok: boolean; output: string }> {
  const result = await $`nix build ${NIX_BUILD_TARGET}`.quiet().nothrow();
  const output = result.stderr.toString() + result.stdout.toString();
  return { ok: result.exitCode === 0, output };
}

async function commit(message: string): Promise<void> {
  await $`git add ${CADDY_FILE}`;
  await $`git commit -m ${message}`;
  console.log(`done — committed`);
}

// --- main ---

const latestVersion = await fetchLatestVersion();
let caddyNix = await readCaddyNix();
const oldVersion = currentVersionIn(caddyNix);

const versionChanged = oldVersion !== latestVersion;
if (versionChanged) {
  console.log(`updating caddy-tailscale: ${oldVersion} → ${latestVersion}`);
  caddyNix = caddyNix.replace(
    /caddy-tailscale@[^"]+/,
    `caddy-tailscale@${latestVersion}`,
  );
  await writeCaddyNix(caddyNix);
} else {
  console.log(`caddy-tailscale already at ${latestVersion}`);
}

const firstAttempt = await tryBuild();
if (firstAttempt.ok) {
  if (versionChanged) {
    await commit(`caddy: update caddy-tailscale to ${latestVersion}`);
  } else {
    console.log("already up to date");
  }
  process.exit(0);
}

// Hash mismatch — blank it so nix tells us the correct one.
console.log("hash is stale, fetching new hash...");
caddyNix = (await readCaddyNix()).replace(/hash = "sha256-[^"]*"/, 'hash = ""');
await writeCaddyNix(caddyNix);

const blankAttempt = await tryBuild();
const newHash = blankAttempt.output.match(/got:\s+(sha256-\S+)/)?.[1];
if (!newHash) {
  console.error("could not extract new hash from nix output");
  process.stderr.write(blankAttempt.output);
  process.exit(1);
}

caddyNix = (await readCaddyNix()).replace('hash = ""', `hash = "${newHash}"`);
await writeCaddyNix(caddyNix);
console.log(`updated hash: ${newHash}; verifying build`);
await $`nix build ${NIX_BUILD_TARGET}`;

await commit(
  versionChanged
    ? `caddy: update caddy-tailscale to ${latestVersion}`
    : `caddy: update caddy-tailscale hash to ${newHash}`,
);

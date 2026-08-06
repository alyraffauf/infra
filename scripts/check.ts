#!/usr/bin/env bun
// Runs every consistency check and reports all failures (so one broken
// check doesn't hide another). Exits non-zero if any check fails.

import { checkForwardAuth } from "./check-forward-auth.ts";
import { checkChartInventory } from "./check-chart-inventory.ts";
import { checkPinnedImages } from "./check-pinned-images.ts";
import { checkReleaseNames } from "./check-release-names.ts";

const checks = [
  { name: "chart-inventory", run: checkChartInventory },
  { name: "forward-auth", run: checkForwardAuth },
  { name: "release-names", run: checkReleaseNames },
  { name: "pinned-images", run: checkPinnedImages },
];

let failedCount = 0;
for (const check of checks) {
  const errors = await check.run();
  if (errors.length === 0) {
    console.log(`${check.name}: ✓`);
    continue;
  }
  failedCount++;
  for (const error of errors) {
    console.error(`${check.name}: ${error}`);
  }
}

if (failedCount > 0) process.exit(1);

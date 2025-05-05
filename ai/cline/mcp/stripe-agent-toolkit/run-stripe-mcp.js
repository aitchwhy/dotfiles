#!/usr/bin/env node

/**
 * Stripe Agent Toolkit MCP Server
 *
 * This script runs the Stripe Agent Toolkit MCP server using npx.
 *
 * Usage:
 *   node run-stripe-mcp.js
 *
 * Environment variables:
 *   STRIPE_SECRET_KEY - Your Stripe secret key
 */

const { spawn } = require("node:child_process");
const path = require("node:path");

// Check if STRIPE_SECRET_KEY is set
if (!process.env.STRIPE_SECRET_KEY) {
  console.error("Error: STRIPE_SECRET_KEY environment variable is not set.");
  console.error(
    "Please set your Stripe secret key as an environment variable:",
  );
  console.error("  export STRIPE_SECRET_KEY=your_stripe_secret_key");
  process.exit(1);
}

console.log("Starting Stripe Agent Toolkit MCP server...");

// Run the Stripe MCP server using npx
const stripeServer = spawn(
  "npx",
  [
    "-y",
    "@stripe/mcp",
    "--tools=all",
    `--api-key=${process.env.STRIPE_SECRET_KEY}`,
  ],
  {
    stdio: "inherit",
  },
);

stripeServer.on("error", (err) => {
  console.error("Failed to start Stripe MCP server:", err);
  process.exit(1);
});

stripeServer.on("close", (code) => {
  console.log(`Stripe MCP server exited with code ${code}`);
  process.exit(code);
});

console.log("Stripe MCP server is running. Press Ctrl+C to stop.");

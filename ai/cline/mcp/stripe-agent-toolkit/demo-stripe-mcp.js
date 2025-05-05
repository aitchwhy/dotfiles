#!/usr/bin/env node

/**
 * Stripe Agent Toolkit MCP Server Demo Script
 *
 * This script demonstrates how to use the Stripe Agent Toolkit MCP Server tools
 * to interact with Stripe APIs.
 *
 * Usage:
 *   node demo-stripe-mcp.js
 */

// Sample request for creating a customer
const createCustomerRequest = {
  name: "create_customer",
  arguments: {
    email: "customer@example.com",
    name: "Example Customer",
  },
};

// Sample request for listing products
const listProductsRequest = {
  name: "list_products",
  arguments: {
    limit: 5,
  },
};

// Sample request for creating a payment link
const createPaymentLinkRequest = {
  name: "create_payment_link",
  arguments: {
    line_items: [
      {
        price_data: {
          currency: "usd",
          product_data: {
            name: "Demo Product",
          },
          unit_amount: 2000,
        },
        quantity: 1,
      },
    ],
  },
};

// Sample request for retrieving balance
const retrieveBalanceRequest = {
  name: "retrieve_balance",
  arguments: {},
};

console.log("Stripe Agent Toolkit MCP Server Demo");
console.log("====================================");
console.log("\nTo use these tools in Cline, you can ask questions like:");
console.log(
  '- "Create a new Stripe customer with email john@example.com and name John Doe"',
);
console.log('- "Show me all my Stripe products"');
console.log(
  "- \"Create a Stripe payment link for a $20 product called 'Demo Product'\"",
);
console.log('- "What\'s my current Stripe balance?"');

console.log("\nSample MCP Tool Requests:");
console.log("\n1. Create Customer Request:");
console.log(JSON.stringify(createCustomerRequest, null, 2));

console.log("\n2. List Products Request:");
console.log(JSON.stringify(listProductsRequest, null, 2));

console.log("\n3. Create Payment Link Request:");
console.log(JSON.stringify(createPaymentLinkRequest, null, 2));

console.log("\n4. Retrieve Balance Request:");
console.log(JSON.stringify(retrieveBalanceRequest, null, 2));

console.log("\nMCP Server Configuration:");
console.log("- Server Name: github.com/stripe/agent-toolkit");
console.log(
  "- Command: node /Users/hank/dotfiles/config/ai/cline/mcp/stripe-agent-toolkit/run-stripe-mcp.js",
);
console.log(
  "- Configuration File: /Users/hank/dotfiles/config/ai/cline/cline_mcp_settings.json",
);
console.log("- Required Environment Variables: STRIPE_SECRET_KEY");

console.log("\nNote: To use these tools in Cline, you need to:");
console.log("1. Set your Stripe secret key in the MCP settings file");
console.log(
  "2. Restart Cline or reload the window after configuring the MCP server",
);

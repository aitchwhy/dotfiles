# Stripe Agent Toolkit MCP Server

This directory contains the Stripe Agent Toolkit MCP server configuration for Cline.

## Overview

The Stripe Agent Toolkit enables integration with Stripe APIs through function calling. It provides tools for working with Stripe resources such as customers, products, prices, payment links, invoices, and more.

## Configuration

The server is configured in the Cline MCP settings file at:
`/Users/hank/dotfiles/config/ai/cline/cline_mcp_settings.json`

### Required Environment Variables

To use the Stripe Agent Toolkit, you need to set your Stripe secret key in the MCP settings file:

```json
"env": {
  "STRIPE_SECRET_KEY": "sk_test_your_stripe_secret_key"
}
```

You can get your Stripe secret key from the [Stripe Dashboard](https://dashboard.stripe.com/apikeys).

## Supported API Methods

The Stripe Agent Toolkit supports the following API methods:

- Create a customer
- List all customers
- Create a product
- List all products
- Create a price
- List all prices
- Create a payment link
- Create an invoice
- Create an invoice item
- Finalize an invoice
- Retrieve balance
- Create a refund

## Usage Examples

Here are some examples of how to use the Stripe Agent Toolkit in Cline:

1. Create a customer:
   "Create a new Stripe customer with email john@example.com and name John Doe"

2. List products:
   "Show me all my Stripe products"

3. Create a payment link:
   "Create a Stripe payment link for my Basic Plan product"

4. Check balance:
   "What's my current Stripe balance?"

## Troubleshooting

If you encounter issues with the Stripe Agent Toolkit:

1. Ensure your Stripe secret key is correctly set in the MCP settings file
2. Check that the server is not disabled in the MCP settings
3. Restart Cline or reload the window after making changes to the MCP settings

## Resources

- [Stripe API Documentation](https://docs.stripe.com/api)
- [Stripe Agent Toolkit GitHub Repository](https://github.com/stripe/agent-toolkit)

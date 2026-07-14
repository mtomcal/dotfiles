# Mocking External Seams

Use a test adapter only when caller-visible behavior crosses a justified external seam:

- external APIs such as payment or email;
- databases when a faithful test database is impractical (prefer the test database);
- time or randomness; and
- the filesystem when a real temporary filesystem is impractical.

Do not mock your own modules or internal collaborators; exercise them through the public interface. Do not expose an internal seam merely because a test needs it. `codebase-design` owns seam placement and adapter justification.

## Designing a Test Adapter

Add an adapter only for real external variation. A production adapter plus a justified test adapter provides two concrete implementations of the seam.

**1. Use dependency injection**

Pass the external dependency in rather than creating it internally:

```typescript
// Easy to replace with a test adapter
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to replace without reaching into implementation
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer operation-specific interfaces over generic fetchers**

Create a specific operation for each external capability instead of one generic function that forces conditional logic into the test adapter:

```typescript
// GOOD: Each operation has one result shape
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: The test adapter must branch on endpoint and options
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

Operation-specific interfaces give each test adapter one result shape, avoid conditional setup, reveal which external capabilities a test exercises, and preserve per-operation type safety.

# Good and Bad Tests

## Behavior through an interface

```typescript
// GOOD: observable behavior through the public interface
test("user can checkout with a valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

A durable behavior test:

- names a caller-visible capability
- crosses a pre-agreed seam
- uses the public interface
- survives internal refactors
- fails when the behavior breaks

## Implementation coupling

```typescript
// BAD: asserts an internal collaboration
test("checkout calls paymentService.process", async () => {
  const payment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(payment.process).toHaveBeenCalledWith(cart.total);
});
```

Call counts, private methods, internal mocks, or database queries that bypass the public interface test implementation rather than behavior.

```typescript
// GOOD: verification returns through the interface
const user = await createUser({ name: "Alice" });
const retrieved = await getUser(user.id);
expect(retrieved.name).toBe("Alice");
```

## Tautological expectations

```typescript
// BAD: expected value repeats the same algorithm
const items = [{ price: 10 }, { price: 5 }];
const expected = items.reduce((sum, item) => sum + item.price, 0);
expect(calculateTotal(items)).toBe(expected);

// GOOD: expected value comes from an independent worked example
expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
```

A test is tautological when its oracle is derived by the same logic as the implementation. Prefer a spec example, known literal, independently generated fixture, trusted external oracle, or an invariant capable of disagreeing with the code.

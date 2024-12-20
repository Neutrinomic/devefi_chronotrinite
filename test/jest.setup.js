
// jest.setup.js or jest.setup.ts
expect.extend({
    toBeApprox(received, expected, tolerance = 10n) {
      if (typeof received !== 'bigint' || typeof expected !== 'bigint') {
        return {
          message: () => `expected ${received} and ${expected} to be of type BigInt`,
          pass: false,
        };
      }
      const pass = received >= expected - tolerance && received <= expected + tolerance;
      if (pass) {
        return {
          message: () => `expected ${received} not to be approximately ${expected} within tolerance ${tolerance}`,
          pass: true,
        };
      } else {
        return {
          message: () => `expected ${received} to be approximately ${expected} within tolerance ${tolerance}`,
          pass: false,
        };
      }
    },
  });
  
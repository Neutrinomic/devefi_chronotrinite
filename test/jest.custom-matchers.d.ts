// jest.custom-matchers.d.ts
import "jest";

declare global {
  namespace jest {
    interface Matchers<R> {
      toBeApprox(expected: bigint, tolerance?: bigint): R;
    }
  }
}

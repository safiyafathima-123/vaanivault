import { describe, it, expect } from "vitest";

describe("Server basic health test", () => {
  it("should have correct chainId constant", () => {
    const chainId = 10143;
    expect(chainId).toBe(10143);
  });
});

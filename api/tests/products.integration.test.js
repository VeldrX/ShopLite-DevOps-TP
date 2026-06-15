const request = require("supertest");
const app = require("../src/app");

// Run integration tests only if DATABASE_URL is set (CI environment)
const shouldRunIntegration = !!process.env.DATABASE_URL;

if (shouldRunIntegration) {
  describe("Integration tests with PostgreSQL", () => {
    beforeAll(async () => {
      const response = await request(app).get("/health");
      // Fail fast if DB not healthy
      expect(response.status).toBe(200);
    });

    test("GET /products returns array from database", async () => {
      const response = await request(app).get("/products");
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("source", "database");
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    test("GET /products returns empty array initially", async () => {
      const response = await request(app).get("/products");
      expect(response.status).toBe(200);
      expect(response.body.data).toEqual([]);
    });
  });
} else {
  describe("Integration tests (skipped - set DATABASE_URL to run)", () => {
    it("skipped because DATABASE_URL not set", () => {
      // Placeholder test that always passes when not in CI
      expect(true).toBe(true);
    });
  });
}

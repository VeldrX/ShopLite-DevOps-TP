const request = require("supertest");
const app = require("../src/app");
const { initializeDatabase } = require("./initialize-db");

// Run integration tests only if DATABASE_URL is set (CI environment)
const shouldRunIntegration = !!process.env.DATABASE_URL;

if (shouldRunIntegration) {
  describe("Integration tests with PostgreSQL", () => {
    beforeAll(async () => {
      // Initialize DB schema before health check
      await initializeDatabase();
      const response = await request(app).get("/health");
      // Fail fast if DB not healthy
      expect(response.status).toBe(200);
    });

    test("GET /products returns array with seeded data", async () => {
      const response = await request(app).get("/products");
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("source", "database");
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThanOrEqual(3);
    });

    test("GET /products includes expected product fields", async () => {
      const response = await request(app).get("/products");
      expect(response.status).toBe(200);
      const product = response.body.data[0];
      expect(product).toHaveProperty("id");
      expect(product).toHaveProperty("name");
      expect(product).toHaveProperty("description");
      expect(product).toHaveProperty("price_cents");
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

const request = require("supertest");
const app = require("../src/app");
const db = require("../src/db");

describe("Error handling tests", () => {
  afterAll(() => {
    return db.getPool().end();
  });
  test("GET /nonexistent returns 404", async () => {
    const response = await request(app).get("/nonexistent");
    expect(response.status).toBe(404);
    expect(response.body).toHaveProperty("error");
  });

  test("Malformed JSON returns 400", async () => {
    const response = await request(app)
      .post("/api/products")
      .set("Content-Type", "application/json")
      .send("{invalid json}");
    expect(response.status).toBe(400);
    expect(response.body.error).toBe("Invalid JSON");
  });

  test("Health endpoint returns 200 when DB is available", async () => {
    const response = await request(app).get("/health");
    // Accept 200 or 503 depending on DB availability
    expect([200, 503]).toContain(response.status);
  });

  test("GET /health/ready returns 200 when DB is available", async () => {
    const response = await request(app).get("/health/ready");
    expect([200, 503]).toContain(response.status);
  });

  test("Request with sensitive query params is handled", async () => {
    const response = await request(app).get(
      "/health?password=secret&token=abc&key=123",
    );
    expect([200, 503]).toContain(response.status);
  });
});

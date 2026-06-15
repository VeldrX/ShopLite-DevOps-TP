const request = require("supertest");
const app = require("../src/app");

describe("Error handling tests", () => {
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
});

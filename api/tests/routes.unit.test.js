jest.mock("../src/db");

const request = require("supertest");
const db = require("../src/db");
const app = require("../src/app");

describe("Routes unit tests with mocked DB", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("GET /health", () => {
    it("returns 200 when DB query succeeds", async () => {
      db.query.mockResolvedValue({ rows: [] });
      const response = await request(app).get("/health");
      expect(response.status).toBe(200);
      expect(response.body.status).toBe("ok");
      expect(db.query).toHaveBeenCalledWith("SELECT 1");
    });

    it("returns 503 when DB query fails", async () => {
      db.query.mockRejectedValue(new Error("DB connection failed"));
      const response = await request(app).get("/health");
      expect(response.status).toBe(503);
      expect(response.body.status).toBe("error");
    });
  });

  describe("GET /products", () => {
    it("returns 200 and product list when DB succeeds", async () => {
      const mockRows = [
        { id: 1, name: "Test", description: "Desc", price_cents: 100 },
      ];
      db.query.mockResolvedValue({ rows: mockRows });
      const response = await request(app).get("/products");
      expect(response.status).toBe(200);
      expect(response.body.source).toBe("database");
      expect(response.body.data).toEqual(mockRows);
    });

    it("returns 500 when DB query fails", async () => {
      db.query.mockRejectedValue(new Error("DB error"));
      const response = await request(app).get("/products");
      expect(response.status).toBe(500);
    });
  });
});

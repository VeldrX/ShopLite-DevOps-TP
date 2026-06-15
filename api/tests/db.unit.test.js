// Mock pg module before requiring db
jest.mock("pg", () => {
  const mPool = {
    query: jest.fn(),
    connect: jest.fn(),
  };
  return {
    Pool: jest.fn().mockImplementation(() => mPool),
    mPool,
  };
});

describe("db.getPool()", () => {
  beforeEach(() => {
    jest.resetModules();
    process.env.DATABASE_URL = "postgres://test:test@localhost:5432/test";
  });

  test("should create a new pool if none exists", async () => {
    const { getPool } = require("../src/db");
    const pool = getPool();
    expect(pool).toBeDefined();
  });

  test("should return the same pool on subsequent calls", async () => {
    const { getPool } = require("../src/db");
    const pool1 = getPool();
    const pool2 = getPool();
    expect(pool1).toBe(pool2);
  });
});

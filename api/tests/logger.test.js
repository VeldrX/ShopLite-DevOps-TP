const request = require("supertest");
const app = require("../src/app");
const db = require("../src/db");

describe("Logger sanitize branches", () => {
  let consoleSpy;

  beforeEach(() => {
    consoleSpy = jest.spyOn(console, "log").mockImplementation(() => {});
  });

  afterEach(() => {
    consoleSpy.mockRestore();
  });

  afterAll(() => {
    return db.getPool().end();
  });

  it("handles non-sensitive query params (else branch)", async () => {
    await request(app).get("/health?name=test&category=devops");
    expect(consoleSpy).toHaveBeenCalled();
    const log = JSON.parse(consoleSpy.mock.calls[0][0]);
    expect(log.query).toEqual({ name: "test", category: "devops" });
  });

  it("handles array query params (array + nested object branches)", async () => {
    await request(app).get("/health?items=a&items=b");
    expect(consoleSpy).toHaveBeenCalled();
    const log = JSON.parse(consoleSpy.mock.calls[0][0]);
    expect(log.query.items).toEqual(["a", "b"]);
  });

  it("handles mixed sensitive and non-sensitive params", async () => {
    await request(app).get("/health?visible=yes&password=secret&count=3");
    expect(consoleSpy).toHaveBeenCalled();
    const log = JSON.parse(consoleSpy.mock.calls[0][0]);
    expect(log.query.visible).toBe("yes");
    expect(log.query.password).toBe("[REDACTED]");
    expect(log.query.count).toBe("3");
  });
});

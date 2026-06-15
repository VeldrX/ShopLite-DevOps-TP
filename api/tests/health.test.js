const request = require("supertest");
const app = require("../src/app");

test("GET / retourne le nom de l'API", async () => {
  const response = await request(app).get("/");

  expect(response.status).toBe(200);
  expect(response.body.name).toBe("ShopLite API");
});

test("GET /ready retourne ok", async () => {
  const response = await request(app).get("/ready");
  expect(response.status).toBe(200);
  expect(response.body.status).toBe("ok");
});

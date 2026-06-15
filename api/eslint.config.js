import globals from "globals";

export default [
  {
    ignores: ["dist/**", "node_modules/**", "coverage/**"]
  },
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.node,
        ...globals.browser
      }
    },
    rules: {
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "no-console": "off",
      "eqeqeq": ["error", "always"],
      "curly": ["error", "multi-line"],
      "no-throw-literal": "error"
    }
  }
];

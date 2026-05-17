// commitlint config — used by repos that opt in to commitlint via
// `npm install --save-dev @commitlint/cli @commitlint/config-conventional`.
// The bash hook under configurations/git/template/hooks/commit-msg runs
// the same regex without an npm dependency, so commitlint is optional.
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      ["feat", "fix", "refactor", "chore", "docs", "style", "perf", "build", "ci", "test", "revert"],
    ],
    "subject-case": [2, "never", ["upper-case", "pascal-case", "sentence-case", "start-case"]],
    "header-max-length": [2, "always", 100],
    "body-max-line-length": [2, "always", 120],
  },
};

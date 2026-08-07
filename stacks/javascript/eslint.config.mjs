// ESLint 9 "flat config".
//
// Deliberately NOT using type-aware linting (`tseslint.configs.recommendedTypeChecked`).
// Type-aware rules need a `project:` pointing at a tsconfig, and pre-commit invokes
// ESLint from the repository root with a partial file list - a combination that
// produces "file not included in project" errors on the first commit that touches a
// single file. If you want type-aware rules, run them in CI over the whole tree
// instead, and keep the commit hook on the syntactic rules below.

import js from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default [
  {
    ignores: ['dist/**', 'node_modules/**', 'coverage/**'],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{js,mjs,cjs,ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: 'module',
      globals: {
        ...globals.node,
      },
    },
    rules: {
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      eqeqeq: ['error', 'always'],
      'prefer-const': 'error',
    },
  },
];

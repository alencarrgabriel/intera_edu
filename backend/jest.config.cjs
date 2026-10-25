module.exports = {
  testEnvironment: 'node',
  moduleFileExtensions: ['ts', 'js', 'json', 'node'],
  testMatch: ['<rootDir>/test/**/*.test.js'],
  transform: { '^.+\\.ts$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.test.json' }] },
  moduleNameMapper: { '^@interaedu/shared$': '<rootDir>/shared/src/index.ts' },
  setupFiles: ['reflect-metadata'],
  clearMocks: true,
  collectCoverageFrom: ['*/src/**/*.ts', '!**/*.d.ts', '!**/main.ts', '!**/*.module.ts', '!**/database/**', '!**/dto/**', '!**/interfaces/**', '!**/index.ts'],
  coverageDirectory: '../reports/release/backend-coverage',
  coverageReporters: ['text', 'json-summary', 'lcov', 'html'],
};

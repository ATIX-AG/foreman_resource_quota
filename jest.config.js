const {
  foremanRelativePath,
  foremanLocation,
} = require('@theforeman/find-foreman');

const foremanReactRelative = 'webpack/assets/javascripts/react_app';
const foremanFull = foremanLocation();
const foremanReactFull = foremanRelativePath(foremanReactRelative);



// Jest configuration
module.exports = {
// Find correct path to foremanReact so we do not have to mock it in tests

  moduleNameMapper: {
    '^foremanReact(.*)$': `${foremanReactFull}/$1`,
  },

  setupFiles : ['./webpack/core_test_setup.js'],

  setupFilesAfterEnv : [
  './webpack/global_test_setup.js',
  '@testing-library/jest-dom',
  ],

// Do not use default resolver
  resolver : null,
// Specify module dirs instead
  moduleDirectories : [
  `${foremanFull}/node_modules`,
  `${foremanFull}/node_modules/@theforeman/vendor-core/node_modules`,
  'node_modules',
  'webpack/test-utils',
  ],
};

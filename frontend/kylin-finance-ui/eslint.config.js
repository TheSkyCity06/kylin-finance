import js from '@eslint/js'
import globals from 'globals'
import vue from 'eslint-plugin-vue'

export default [
  {
    name: 'app/files-to-lint',
    files: ['**/*.{ts,mts,tsx,vue}'],
  },

  {
    name: 'app/files-to-ignore',
    ignores: ['**/dist/**', '**/dist-ssr/**', '**/coverage/**'],
  },

  js.configs.recommended,
  ...vue.configs['flat/essential'],

  {
    name: 'app/vue-rules',
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: {
        parser: '@babel/eslint-parser',
        requireConfigFile: false,
        sourceType: 'module',
        ecmaVersion: 'latest',
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
  },

  {
    name: 'app/javascript-rules',
    files: ['**/*.{js,mjs,cjs}'],
    languageOptions: {
      globals: globals.browser,
    },
  },
]

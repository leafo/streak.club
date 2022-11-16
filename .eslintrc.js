module.exports = {
    "env": {
        "browser": true,
        "es2021": true
    },
    "extends": [
        "eslint:recommended",
    ],
    "parserOptions": {
        "ecmaFeatures": {
            "jsx": true
        },
        "ecmaVersion": 12,
        "sourceType": "module"
    },
    "plugins": [
    ],
    "rules": {
      "no-unused-vars": "off",
      "no-cond-assign": "off",
      "no-extra-semi": "off",
      "no-empty": "off"
    },
    "globals": { }
};

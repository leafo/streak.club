module.exports = {
    "env": {
        "browser": true,
        "es2021": true,
        "jquery": true
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
    },
    "globals": {
        "S": true,
        "require": true,
        "commonmark": true,
        "_": true,
        "TurndownService": true,
    }
};

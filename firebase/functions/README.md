# Firebase Functions

This folder contains the Cloud Functions source code used by ZeroSpoils.

## What is index.js for?

`index.js` is the Node.js entrypoint for deployed functions in this package. It currently exports:

- `submitFeedbackIngest`: HTTPS callable endpoint that validates/authenticates feedback submissions and writes to Firestore.

The package entrypoint is defined in `package.json` (`"main": "index.js"`).

## Is this connected to root firebase.json?

Yes.

Root `firebase.json` configures Functions with:

- `functions.source: "firebase/functions"`

That tells the Firebase CLI to build/deploy functions from this folder when you run deploy commands.

`firebase.json` also sets Firestore rules path:

- `firestore.rules: "app/firestore.rules"`

So the root config wires multiple Firebase products in one place.

## Common commands

From repo root:

```bash
cd firebase/functions
npm ci
npm run serve
npm run deploy
```

## Version control notes

Keep these files in git:

- `index.js`
- `package.json`
- `package-lock.json`

Do not commit generated dependencies:

- `firebase/functions/node_modules/` (ignored by root `.gitignore`)

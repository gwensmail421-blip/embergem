// Turns game/embergem.html (the same file published as the preview Artifact) into the
// app's offline web bundle: a full document, viewport for the notch, fonts served locally.
const fs = require("fs");
const src = fs.readFileSync(__dirname + "/../game/embergem.html", "utf8");
const body = src
  .replace(/<link rel="preconnect"[^>]*>\n?/, "")
  .replace(/<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com[^>]*>/, '<link rel="stylesheet" href="fonts/fonts.css">');
if (/fonts\.googleapis/.test(body)) throw new Error("remote font link left in the bundle");
const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<meta name="color-scheme" content="dark">
${body}
`;
fs.writeFileSync(__dirname + "/../www/index.html", html);
console.log("www/index.html written,", html.length, "bytes");

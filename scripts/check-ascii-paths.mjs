import { readdir, readFile } from 'node:fs/promises';
import { extname, join, relative } from 'node:path';

const ROOT = process.cwd();
const ALLOWED_DIRS = new Set(['.git', 'node_modules', 'dist']);
const CODE_EXT = new Set(['.js', '.mjs', '.jsx', '.ts', '.tsx']);
const nonAsciiRegex = /[^\x00-\x7F]/;
const importRegex = /(?:import|export)\s[^'"`]*['"]([^'"]+)['"]/g;

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (ALLOWED_DIRS.has(entry.name)) {
      continue;
    }
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await walk(fullPath)));
    } else {
      files.push(fullPath);
    }
  }
  return files;
}

const files = await walk(ROOT);
const invalidPaths = [];
const invalidImports = [];

for (const filePath of files) {
  const relPath = relative(ROOT, filePath);
  if (nonAsciiRegex.test(relPath) || /\s/.test(relPath)) {
    invalidPaths.push(relPath);
  }

  if (!CODE_EXT.has(extname(filePath))) {
    continue;
  }
  const content = await readFile(filePath, 'utf8');
  for (const match of content.matchAll(importRegex)) {
    const specifier = match[1];
    if (nonAsciiRegex.test(specifier) || /\s/.test(specifier)) {
      invalidImports.push(`${relPath}: ${specifier}`);
    }
  }
}

if (invalidPaths.length > 0 || invalidImports.length > 0) {
  console.error('Se detectaron rutas/imports no ASCII o con espacios.');
  if (invalidPaths.length > 0) {
    console.error('Paths inválidos:');
    for (const pathItem of invalidPaths) {
      console.error(` - ${pathItem}`);
    }
  }
  if (invalidImports.length > 0) {
    console.error('Imports inválidos:');
    for (const importItem of invalidImports) {
      console.error(` - ${importItem}`);
    }
  }
  process.exit(1);
}

console.log('OK: no hay rutas ni imports no-ASCII/con espacios.');

import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';

const distDir = new URL('../dist/', import.meta.url);
if (!existsSync(distDir)) {
  await mkdir(distDir, { recursive: true });
}
await cp(new URL('../src/', import.meta.url), new URL('../dist/src/', import.meta.url), { recursive: true });

const html = await readFile(new URL('../index.html', import.meta.url), 'utf8');
await writeFile(new URL('../dist/index.html', import.meta.url), html);
console.log('Build estático completado en dist/.');

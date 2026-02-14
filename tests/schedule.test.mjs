import test from 'node:test';
import assert from 'node:assert/strict';
import { hasConflict } from '../src/utils/schedule.js';

test('detecta choque para el mismo profesional', () => {
  const existing = [
    { profesional: 'A', inicio: '2026-02-15T09:00:00-03:00', fin: '2026-02-15T10:00:00-03:00' }
  ];
  const next = { profesional: 'A', inicio: '2026-02-15T09:30:00-03:00', fin: '2026-02-15T10:30:00-03:00' };
  assert.equal(hasConflict(existing, next), true);
});

test('permite horarios sin traslape', () => {
  const existing = [
    { profesional: 'A', inicio: '2026-02-15T09:00:00-03:00', fin: '2026-02-15T10:00:00-03:00' }
  ];
  const next = { profesional: 'A', inicio: '2026-02-15T10:00:00-03:00', fin: '2026-02-15T11:00:00-03:00' };
  assert.equal(hasConflict(existing, next), false);
});

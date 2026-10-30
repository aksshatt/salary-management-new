// Browser APIs Ant Design uses that jsdom doesn't provide.
// Import this first in component tests that run in jsdom.
window.matchMedia ??= () => ({ matches: false, addEventListener() {}, removeEventListener() {} })

globalThis.ResizeObserver ??= class {
  observe() {}
  unobserve() {}
  disconnect() {}
}

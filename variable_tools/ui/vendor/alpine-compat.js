// SketchUp 2019's CEF 64 predates these APIs used by Alpine.
if (!window.queueMicrotask) {
  window.queueMicrotask = function (callback) {
    Promise.resolve().then(callback).catch((error) => setTimeout(() => { throw error; }));
  };
}

if (!Array.prototype.flatMap) {
  Object.defineProperty(Array.prototype, 'flatMap', {
    configurable: true,
    writable: true,
    value(callback, receiver) {
      const result = [];
      this.forEach((value, index) => {
        const mapped = callback.call(receiver, value, index, this);
        if (Array.isArray(mapped)) mapped.forEach((item) => result.push(item));
        else result.push(mapped);
      });
      return result;
    }
  });
}

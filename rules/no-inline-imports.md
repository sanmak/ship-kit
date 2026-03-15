# No Inline Imports

All module import statements must appear at the **top of the file**, before any other code. This applies across all languages and import syntaxes: `import`, `require`, `from X import Y`, and equivalents.

Never place import statements inside functions, conditionals, loops, or any other block scope.

## Requirements

1. **Top-level only.** Every static import or require call must be placed at the module's top level, grouped together at the beginning of the file.
2. **No imports inside functions or blocks.** Do not nest `import`, `require`, or `from X import Y` statements inside functions, `if` blocks, `try/catch`, loops, or class methods.
3. **Exception: dynamic `import()` for code splitting.** Inline dynamic `import()` expressions that return a Promise are allowed when used intentionally for lazy loading or code splitting. These are fundamentally different from static imports -- they are asynchronous expressions, not declarations.

## Good Examples

All imports at the top of the module:

```ts
import { readFile } from "fs/promises";
import path from "path";
import { parse } from "./parser";

export async function loadConfig(filePath: string) {
  const raw = await readFile(path.resolve(filePath), "utf-8");
  return parse(raw);
}
```

```python
import os
from pathlib import Path
from .parser import parse

def load_config(file_path: str):
    raw = Path(file_path).read_text()
    return parse(raw)
```

Dynamic `import()` for lazy loading (allowed exception):

```ts
import { useState, useEffect } from "react";

export function HeavyComponent() {
  const [mod, setMod] = useState(null);

  useEffect(() => {
    // Allowed: dynamic import() returning a Promise for code splitting
    import("./heavy-module").then((m) => setMod(m));
  }, []);

  return mod ? <mod.Widget /> : <p>Loading...</p>;
}
```

## Bad Examples

Import inside a function:

```ts
// BAD: static import buried inside a function body
export function loadConfig(filePath: string) {
  const { readFile } = require("fs/promises"); // BAD
  const path = require("path");                // BAD
  return readFile(path.resolve(filePath), "utf-8");
}
```

Import inside a conditional:

```python
# BAD: import hidden inside an if block
def connect(use_ssl: bool):
    if use_ssl:
        import ssl  # BAD
        return ssl.create_default_context()
    return None
```

Require inside a try/catch:

```ts
// BAD: require inside a try block
export function getParser() {
  try {
    const { parse } = require("./optional-parser"); // BAD
    return parse;
  } catch {
    return null;
  }
}
```

## Enforcement

During any code generation or editing:

- Place all import and require statements at the top of the file, before any function definitions, class declarations, or executable code.
- If an existing file has inline imports, refactor them to the top of the module when touching that code.
- Only allow inline `import()` when it is a dynamic expression (returns a Promise) used for code splitting or lazy loading. Static `require()` or `import` declarations must never appear inline.

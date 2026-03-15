# TypeScript Exhaustive Switch Handling

Every `switch` statement operating on a union type or enum in TypeScript **must** handle all possible cases exhaustively. This prevents silent bugs when new members are added to a union or enum but existing switch statements are not updated.

## Requirements

1. **Enumerate every member explicitly** in individual `case` clauses, OR
2. **Include a `default` case with a `never` assertion** that makes the compiler emit an error if a case is unhandled:

```ts
default: {
  const _exhaustive: never = value;
  throw new Error(`Unhandled case: ${_exhaustive}`);
}
```

Either approach is acceptable. The key guarantee is that adding a new member to the union or enum must produce a compile-time error if the switch is not updated.

## Good Examples

Explicitly handling every case:

```ts
type Status = "idle" | "loading" | "success" | "error";

function statusMessage(status: Status): string {
  switch (status) {
    case "idle":
      return "Waiting to start.";
    case "loading":
      return "Loading...";
    case "success":
      return "Done!";
    case "error":
      return "Something went wrong.";
  }
}
```

Using a `never` assertion in the default branch:

```ts
enum Direction {
  Up,
  Down,
  Left,
  Right,
}

function move(direction: Direction): void {
  switch (direction) {
    case Direction.Up:
      moveUp();
      break;
    case Direction.Down:
      moveDown();
      break;
    case Direction.Left:
      moveLeft();
      break;
    case Direction.Right:
      moveRight();
      break;
    default: {
      const _exhaustive: never = direction;
      throw new Error(`Unhandled direction: ${_exhaustive}`);
    }
  }
}
```

## Bad Examples

Missing a union member with no safety net:

```ts
type Status = "idle" | "loading" | "success" | "error";

function statusMessage(status: Status): string {
  switch (status) {
    case "idle":
      return "Waiting to start.";
    case "loading":
      return "Loading...";
    case "success":
      return "Done!";
    // BAD: "error" is not handled, and there is no default with a never assertion.
  }
}
```

Using a `default` that silently swallows unknown cases:

```ts
enum Direction {
  Up,
  Down,
  Left,
  Right,
}

function move(direction: Direction): void {
  switch (direction) {
    case Direction.Up:
      moveUp();
      break;
    case Direction.Down:
      moveDown();
      break;
    default:
      // BAD: silently ignores Left and Right. If new members are added
      // to the enum, this will hide the oversight at compile time.
      break;
  }
}
```

## Enforcement

During any code generation or editing that involves a TypeScript `switch` statement on a union type or enum:

- Verify that every member of the type is covered by a `case` clause, **or** that the `default` branch contains a `never` assertion (`const _exhaustive: never = value`).
- If a new member is added to a union or enum, update all related switch statements to remain exhaustive.
- Do not add a plain `default` branch that silently falls through or returns a generic value, as this defeats the purpose of compile-time exhaustiveness checking.

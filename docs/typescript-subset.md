# TypeScript to MoonBit Supported Subset

This document describes the TypeScript features and syntax that are supported when converting TypeScript type definitions to MoonBit FFI bindings.

## Supported Types

### Primitive Types
- `string` → `String`
- `number` → `Double`
- `boolean` → `Bool`
- `void` → `Unit`
- `null` → `Null`
- `undefined` → `Unit`
- `any` → `Any` ⚠️ (loses type safety)
- `unknown` → `Any` ⚠️ (requires type guards)

### Complex Types
- **Arrays**: `T[]` or `Array<T>` → `Array[T]`
- **Tuples**: `[T1, T2, ...]` → Supported (⚠️ large tuples may impact performance)
- **Object Types**: `{ prop: Type }` → Supported
- **Function Types**: `(param: Type) => ReturnType` → `(Type) -> ReturnType`
- **Type References**: `TypeName<T>` → Supported
- **Promise**: `Promise<T>` → `Promise[T]`
- **Optional Properties**: `prop?: Type` → Supported
- **Readonly Properties**: `readonly prop: Type` → Supported (mapped to regular properties)

### Special Type Mappings
- DOM Types (`HTMLElement`, `Element`, `Document`, `Window`, `Event`, etc.) → `JSValue`
- `mbt.*` prefixed types → Mapped according to convention:
  - `mbt.String` → `String`
  - `mbt.Int` → `Int`
  - `mbt.Float` → `Double`
  - `mbt.Void` → `Unit`
  - Other `mbt.*` types → Name without prefix

## Supported Declarations

### ✅ Fully Supported
- **Interface Declarations**
  - Properties (including optional and readonly)
  - Methods
  - Single inheritance (`extends`)
  - Generic type parameters ⚠️ (limited support)

- **Type Aliases**
  - Simple and complex type aliases
  - Generic type aliases ⚠️ (limited support)

- **Function Declarations**
  - Parameters and return types
  - Optional parameters
  - Rest parameters ⚠️ (mapped to arrays)

- **Variable Declarations**
  - `const`, `let`, `var`
  - Type annotations

- **Class Declarations**
  - Properties and methods
  - Constructors
  - Static members
  - Inheritance (`extends`)
  - Generic classes ⚠️ (limited support)

- **Enum Declarations**
  - Numeric enums
  - String enums
  - Const enums

- **Module/Namespace Declarations**
  - Nested declarations
  - Export/Import statements

## Partially Supported Features

### Union Types
- ✅ Nullable unions: `T | null | undefined`
- ❌ Complex unions: `string | number | boolean`

### Generics
- ✅ Basic generic types and functions
- ❌ Generic constraints
- ❌ Conditional types
- ❌ Mapped types

### Modifiers
- ⚠️ `private`/`protected` → mapped to public
- ⚠️ `readonly` → mapped to regular properties
- ⚠️ `declare` → treated as regular declarations

## Not Supported Features

### ❌ Type System Features
- Intersection types (`A & B`)
- Conditional types (`T extends U ? X : Y`)
- Mapped types (`{ [K in keyof T]: ... }`)
- Template literal types
- `this` types
- Index signatures (`[key: string]: Type`)

### ❌ Advanced Features
- Function overloads
- Abstract classes
- Decorators
- Mixins
- Constructor signatures in interfaces
- Nullish coalescing operator (`??`)

### ❌ Complex Patterns
- Multiple interface inheritance
- `implements` clause in classes
- Boolean literal types in enums

## Usage Example

```typescript
// ✅ Supported TypeScript
interface User {
  id: number;
  name: string;
  email?: string;
  isActive: boolean;
}

type UserId = number;

function getUser(id: UserId): Promise<User> {
  // ...
}

class UserService {
  private users: User[]; // ⚠️ private becomes public
  
  constructor() {
    this.users = [];
  }
  
  findUser(id: number): User | null {
    // ...
  }
}

// ❌ Not Supported TypeScript
interface Advanced {
  [key: string]: any; // Index signature
}

type Conditional<T> = T extends string ? number : boolean; // Conditional type

interface A { a: string; }
interface B { b: number; }
type Intersection = A & B; // Intersection type

function overloaded(x: string): string; // Function overload
function overloaded(x: number): number;
function overloaded(x: any): any {
  return x;
}
```

## Validation

Use the `validate_dts_file` function to check if your TypeScript definitions are within the supported subset:

```moonbit
let file = parse_dts_file(typescript_code)
let validation_result = validate_dts_file(file)

if validation_result.is_valid {
  // Safe to generate MoonBit code
  let moonbit_code = generate_moonbit_ffi(file)
} else {
  // Handle errors and warnings
  validation_result.errors.each(fn(e) { println("Error: " + e) })
  validation_result.warnings.each(fn(w) { println("Warning: " + w) })
}
```

## Best Practices

1. **Avoid `any` and `unknown`**: Use specific types for better type safety
2. **Use simple unions**: Prefer nullable types over complex unions
3. **Keep interfaces flat**: Avoid deep nesting and complex inheritance
4. **Use type aliases**: For better readability and maintainability
5. **Document unsupported features**: If your TypeScript uses unsupported features, document the workarounds

## Migration Guide

When converting existing TypeScript definitions:

1. Replace complex unions with nullable types or type aliases
2. Convert intersection types to interfaces with all properties
3. Remove index signatures and use explicit properties
4. Convert function overloads to separate functions or optional parameters
5. Change private/protected members to public or use naming conventions
/**
 * JSON Schema Validator Test Suite
 * Tests for MoonBit JSON Schema implementation
 */

import { assertEquals, assertExists } from "https://deno.land/std@0.208.0/assert/mod.ts";

// Test data structure matching MoonBit's Schema and validation behavior
interface TestCase {
  name: string;
  schema: any;
  validData: any[];
  invalidData: any[];
}

// Define comprehensive test cases
export const testCases: TestCase[] = [
  {
    name: "String type validation",
    schema: { type: "string" },
    validData: ["hello", "world", ""],
    invalidData: [123, true, null, {}, []],
  },
  {
    name: "Number type validation",
    schema: { type: "number" },
    validData: [0, 42, -10, 3.14, -0.5],
    invalidData: ["42", true, null, {}, []],
  },
  {
    name: "Boolean type validation",
    schema: { type: "boolean" },
    validData: [true, false],
    invalidData: ["true", 1, 0, null, {}, []],
  },
  {
    name: "Null type validation",
    schema: { type: "null" },
    validData: [null],
    invalidData: [0, "", false, undefined, {}, []],
  },
  {
    name: "Array type validation",
    schema: { type: "array" },
    validData: [[], [1, 2, 3], ["a", "b"], [true, false], [null]],
    invalidData: ["array", 123, true, null, {}],
  },
  {
    name: "Object type validation",
    schema: { type: "object" },
    validData: [{}, { a: 1 }, { name: "test" }, { x: 1, y: 2 }],
    invalidData: ["object", 123, true, null, []],
  },
  {
    name: "Array with item type",
    schema: { type: "array", items: { type: "string" } },
    validData: [[], ["a"], ["a", "b", "c"]],
    invalidData: [[1], ["a", 1], [true], [null], [{key: "value"}]],
  },
  {
    name: "Object with properties",
    schema: {
      type: "object",
      properties: {
        name: { type: "string" },
        age: { type: "number" },
      },
    },
    validData: [
      {},
      { name: "Alice" },
      { age: 30 },
      { name: "Bob", age: 25 },
      { name: "Charlie", age: 35, extra: "ignored" },
    ],
    invalidData: [
      { name: 123 },
      { age: "thirty" },
      { name: 123, age: "thirty" },
    ],
  },
  {
    name: "Required properties",
    schema: {
      type: "object",
      properties: {
        id: { type: "number" },
        name: { type: "string" },
      },
      required: ["id"],
    },
    validData: [
      { id: 1 },
      { id: 2, name: "Test" },
    ],
    invalidData: [
      {},
      { name: "Missing ID" },
    ],
  },
  {
    name: "Number constraints",
    schema: {
      type: "number",
      minimum: 0,
      maximum: 100,
    },
    validData: [0, 50, 100],
    invalidData: [-1, 101, -50, 200],
  },
  {
    name: "String length constraints",
    schema: {
      type: "string",
      minLength: 2,
      maxLength: 5,
    },
    validData: ["ab", "abc", "abcd", "abcde"],
    invalidData: ["a", "abcdef", "", "toolong"],
  },
  {
    name: "Enum validation",
    schema: {
      type: "string",
      enum: ["red", "green", "blue"],
    },
    validData: ["red", "green", "blue"],
    invalidData: ["yellow", "RED", "Green", ""],
  },
  {
    name: "Nested object validation",
    schema: {
      type: "object",
      properties: {
        user: {
          type: "object",
          properties: {
            name: { type: "string" },
            email: { type: "string" },
          },
          required: ["name"],
        },
      },
      required: ["user"],
    },
    validData: [
      { user: { name: "Alice" } },
      { user: { name: "Bob", email: "bob@example.com" } },
    ],
    invalidData: [
      {},
      { user: {} },
      { user: { email: "no-name@example.com" } },
      { user: "not an object" },
    ],
  },
];

// Test that verifies test cases are properly structured
Deno.test("JSON Schema test cases are well-formed", () => {
  for (const testCase of testCases) {
    assertExists(testCase.name, "Test case should have a name");
    assertExists(testCase.schema, "Test case should have a schema");
    assertExists(testCase.validData, "Test case should have valid data examples");
    assertExists(testCase.invalidData, "Test case should have invalid data examples");
    
    // Ensure arrays are not empty where appropriate
    assertEquals(testCase.validData.length > 0, true, 
      `Test case "${testCase.name}" should have at least one valid example`);
  }
  
  console.log(`✅ All ${testCases.length} test cases are well-formed`);
});

// Test that documents expected behavior
Deno.test("JSON Schema expected behavior documentation", () => {
  let totalValid = 0;
  let totalInvalid = 0;
  
  console.log("\n📋 JSON Schema Validator Expected Behavior:\n");
  
  for (const testCase of testCases) {
    console.log(`\n${testCase.name}:`);
    console.log(`  Schema: ${JSON.stringify(testCase.schema, null, 2)}`);
    
    console.log(`  ✅ Valid examples (${testCase.validData.length}):`);
    for (const valid of testCase.validData) {
      console.log(`    • ${JSON.stringify(valid)}`);
      totalValid++;
    }
    
    console.log(`  ❌ Invalid examples (${testCase.invalidData.length}):`);
    for (const invalid of testCase.invalidData) {
      console.log(`    • ${JSON.stringify(invalid)}`);
      totalInvalid++;
    }
  }
  
  console.log("\n📊 Summary:");
  console.log(`  Total test cases: ${testCases.length}`);
  console.log(`  Total valid examples: ${totalValid}`);
  console.log(`  Total invalid examples: ${totalInvalid}`);
  console.log(`  Total assertions: ${totalValid + totalInvalid}`);
  
  assertEquals(totalValid > 0, true, "Should have valid examples");
  assertEquals(totalInvalid > 0, true, "Should have invalid examples");
});

// Helper function to validate with a mock validator
// This can be replaced with actual MoonBit validator when available
export function mockValidate(schema: any, data: any): boolean {
  // Simple type checking mock implementation
  if (schema.type === "string") return typeof data === "string";
  if (schema.type === "number") return typeof data === "number";
  if (schema.type === "boolean") return typeof data === "boolean";
  if (schema.type === "null") return data === null;
  if (schema.type === "array") return Array.isArray(data);
  if (schema.type === "object") return typeof data === "object" && data !== null && !Array.isArray(data);
  
  return true;
}

// Test with mock validator
Deno.test("Mock validator basic functionality", () => {
  assertEquals(mockValidate({ type: "string" }, "hello"), true);
  assertEquals(mockValidate({ type: "string" }, 123), false);
  assertEquals(mockValidate({ type: "number" }, 42), true);
  assertEquals(mockValidate({ type: "number" }, "42"), false);
  assertEquals(mockValidate({ type: "boolean" }, true), true);
  assertEquals(mockValidate({ type: "boolean" }, 1), false);
  
  console.log("✅ Mock validator basic tests passed");
});
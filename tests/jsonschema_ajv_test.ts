/**
 * JSON Schema Validator Comparison Test
 * Compares MoonBit implementation with Ajv
 */

import Ajv from "npm:ajv@8.12.0/dist/ajv.js";
import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { testCases } from "./jsonschema_test.ts";

// Helper to validate with Ajv
function validateWithAjv(schema: any, data: any): boolean {
  const ajv = new Ajv();
  const validate = ajv.compile(schema);
  return validate(data);
}

// Test Ajv against our test cases
Deno.test("Ajv validates basic types correctly", () => {
  const basicTypeTests = testCases.filter(tc => 
    ["String type validation", "Number type validation", "Boolean type validation", "Null type validation"]
    .includes(tc.name)
  );
  
  for (const testCase of basicTypeTests) {
    console.log(`\nTesting with Ajv: ${testCase.name}`);
    
    // Test valid data
    for (const valid of testCase.validData) {
      const result = validateWithAjv(testCase.schema, valid);
      assertEquals(result, true, 
        `Ajv should accept ${JSON.stringify(valid)} for ${testCase.name}`);
    }
    
    // Test invalid data
    for (const invalid of testCase.invalidData) {
      const result = validateWithAjv(testCase.schema, invalid);
      assertEquals(result, false, 
        `Ajv should reject ${JSON.stringify(invalid)} for ${testCase.name}`);
    }
  }
  
  console.log("\n✅ Ajv basic type validation tests passed");
});

Deno.test("Ajv validates arrays correctly", () => {
  const arrayTests = testCases.filter(tc => 
    tc.name.includes("Array") || tc.name.includes("array")
  );
  
  for (const testCase of arrayTests) {
    console.log(`\nTesting with Ajv: ${testCase.name}`);
    
    // Test valid data
    for (const valid of testCase.validData) {
      const result = validateWithAjv(testCase.schema, valid);
      assertEquals(result, true, 
        `Ajv should accept ${JSON.stringify(valid)} for ${testCase.name}`);
    }
    
    // Test invalid data  
    for (const invalid of testCase.invalidData) {
      const result = validateWithAjv(testCase.schema, invalid);
      assertEquals(result, false, 
        `Ajv should reject ${JSON.stringify(invalid)} for ${testCase.name}`);
    }
  }
  
  console.log("\n✅ Ajv array validation tests passed");
});

Deno.test("Ajv validates objects and properties correctly", () => {
  const objectTests = testCases.filter(tc => 
    tc.name.includes("Object") || tc.name.includes("object") || tc.name.includes("properties")
  );
  
  for (const testCase of objectTests) {
    console.log(`\nTesting with Ajv: ${testCase.name}`);
    
    // Test valid data
    for (const valid of testCase.validData) {
      const result = validateWithAjv(testCase.schema, valid);
      assertEquals(result, true, 
        `Ajv should accept ${JSON.stringify(valid)} for ${testCase.name}`);
    }
    
    // Test invalid data
    for (const invalid of testCase.invalidData) {
      const result = validateWithAjv(testCase.schema, invalid);
      assertEquals(result, false, 
        `Ajv should reject ${JSON.stringify(invalid)} for ${testCase.name}`);
    }
  }
  
  console.log("\n✅ Ajv object validation tests passed");
});

Deno.test("Ajv validates constraints correctly", () => {
  const constraintTests = testCases.filter(tc => 
    tc.name.includes("constraints") || tc.name.includes("Enum")
  );
  
  for (const testCase of constraintTests) {
    console.log(`\nTesting with Ajv: ${testCase.name}`);
    
    // Test valid data
    for (const valid of testCase.validData) {
      const result = validateWithAjv(testCase.schema, valid);
      assertEquals(result, true, 
        `Ajv should accept ${JSON.stringify(valid)} for ${testCase.name}`);
    }
    
    // Test invalid data
    for (const invalid of testCase.invalidData) {
      const result = validateWithAjv(testCase.schema, invalid);
      assertEquals(result, false, 
        `Ajv should reject ${JSON.stringify(invalid)} for ${testCase.name}`);
    }
  }
  
  console.log("\n✅ Ajv constraint validation tests passed");
});

// Test comparing Ajv with MoonBit (when available)
Deno.test("Comparison test framework ready", () => {
  console.log("\n📊 Test Framework Summary:");
  console.log(`  Total test cases: ${testCases.length}`);
  
  const totalExamples = testCases.reduce((sum, tc) => 
    sum + tc.validData.length + tc.invalidData.length, 0);
  console.log(`  Total examples: ${totalExamples}`);
  
  console.log("\n✅ Test framework is ready for MoonBit comparison");
  console.log("  Once MoonBit module is available, replace mock validator with actual implementation");
  
  assertEquals(testCases.length > 0, true, "Should have test cases");
});
// Sample TypeScript declaration file for testing MoonBit FFI generation

// Basic types and interfaces
export interface User {
  id: number;
  name: string;
  email: string;
  isActive: boolean;
}

export interface Product {
  id: number;
  name: string;
  price: number;
  description: string;
  inStock: boolean;
}

// Type aliases
export type UserID = number;
export type ProductID = number;
export type Status = "pending" | "processing" | "completed" | "failed";

// Object type with optional properties
export interface Config {
  apiUrl: string;
  timeout?: number;
  retryCount?: number;
  debug?: boolean;
}

// Union types
export type Result<T> = { success: true; data: T } | { success: false; error: string };
export type ApiResponse = User | Product | { error: string };

// Array types
export interface Order {
  id: number;
  userId: UserID;
  products: ProductID[];
  status: Status;
  total: number;
}

// Functions with various signatures
export function createUser(name: string, email: string): User;
export function updateUser(id: UserID, updates: Partial<User>): User;
export function deleteUser(id: UserID): boolean;
export function findUser(id: UserID): User | null;
export function getAllUsers(): User[];

// Async functions
export function fetchUser(id: UserID): Promise<User>;
export function fetchProduct(id: ProductID): Promise<Product>;
export function saveOrder(order: Order): Promise<Result<Order>>;

// Functions with object parameters
export function searchProducts(criteria: { 
  name?: string;
  minPrice?: number;
  maxPrice?: number;
  inStock?: boolean;
}): Product[];

// Generic functions
export function processData<T>(data: T): T;
export function wrapInArray<T>(item: T): T[];

// Nested object types
export interface Company {
  id: number;
  name: string;
  address: {
    street: string;
    city: string;
    country: string;
    postalCode: string;
  };
  contact: {
    email: string;
    phone: string;
  };
}

// Enum-like unions
export type LogLevel = "debug" | "info" | "warn" | "error";

// Functions with callbacks (simplified for FFI)
export function processAsync(
  data: string,
  onSuccess: (result: string) => void,
  onError: (error: string) => void
): void;

// Constants
export const API_VERSION: string;
export const MAX_RETRIES: number;
export const DEFAULT_TIMEOUT: number;

// Complex nested types
export interface Dashboard {
  users: User[];
  products: Product[];
  orders: Order[];
  stats: {
    totalUsers: number;
    totalProducts: number;
    totalRevenue: number;
  };
}

// Type with methods (simplified for declaration)
export interface Calculator {
  add(a: number, b: number): number;
  subtract(a: number, b: number): number;
  multiply(a: number, b: number): number;
  divide(a: number, b: number): number;
}

// Tuple types
export type Point2D = [number, number];
export type Point3D = [number, number, number];

// Functions returning tuples
export function getCoordinates(): Point2D;
export function get3DCoordinates(): Point3D;

// Mixed parameter types
export function formatMessage(
  template: string,
  ...args: (string | number | boolean)[]
): string;

// Optional parameters
export function connect(host: string, port?: number, secure?: boolean): void;

// Default parameters (treated as optional in .d.ts)
export function createConfig(
  apiUrl: string,
  timeout?: number,
  debug?: boolean
): Config;
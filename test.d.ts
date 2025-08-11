// Sample TypeScript definition file for testing
export interface User {
  id: number;
  name: string;
  email?: string;
}

export type UserID = string;

export function getUser(id: UserID): User;

export class UserService {
  constructor(apiKey: string);
  getUser(id: string): Promise<User>;
  updateUser(id: string, data: Partial<User>): Promise<User>;
}

// Sample TypeScript definition file for testing
export interface User {
  id: number;
  name: string;
  email?: string;
}

export type UserID = string;

export function getUser(id: UserID): User;

export class UserService {
  constructor(private apiKey: string);
  getUser(id: string): Promise<User>;
  updateUser(id: string, data: Partial<User>): Promise<User>;
}

import { Component } from 'react';

export interface Props {
  user: User;
  onUpdate: (user: User) => void;
}
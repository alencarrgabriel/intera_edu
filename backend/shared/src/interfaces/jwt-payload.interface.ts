export interface JwtPayload {
  sub: string;          // User ID
  email: string;
  institution_id: string;
  roles: string[];
  iat?: number;
  exp?: number;
}

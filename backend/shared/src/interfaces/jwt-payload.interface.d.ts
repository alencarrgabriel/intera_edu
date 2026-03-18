export interface JwtPayload {
    sub: string;
    email: string;
    institution_id: string;
    roles: string[];
    iat?: number;
    exp?: number;
}

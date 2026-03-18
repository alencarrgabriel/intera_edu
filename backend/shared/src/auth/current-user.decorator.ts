import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import { JwtPayload } from '../interfaces/jwt-payload.interface';

export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

export const CurrentUser = createParamDecorator(
  (data: keyof JwtPayload | undefined, ctx: ExecutionContext): JwtPayload | JwtPayload[keyof JwtPayload] => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as JwtPayload;
    return data ? (user?.[data] as JwtPayload[keyof JwtPayload]) : user;
  },
);

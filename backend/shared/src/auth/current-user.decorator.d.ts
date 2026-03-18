import { JwtPayload } from '../interfaces/jwt-payload.interface';
export declare const IS_PUBLIC_KEY = "isPublic";
export declare const Public: () => import("@nestjs/common").CustomDecorator<string>;
export declare const CurrentUser: (...dataOrPipes: (import("@nestjs/common").PipeTransform<any, any> | keyof JwtPayload | import("@nestjs/common").Type<import("@nestjs/common").PipeTransform<any, any>> | undefined)[]) => ParameterDecorator;

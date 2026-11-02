import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { map } from 'rxjs';

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler) {
    return next.handle().pipe(
      map((result: unknown) => {
        if (result && typeof result === 'object' && 'isSuccess' in result)
          return result;
        const status = context
          .switchToHttp()
          .getResponse<{ statusCode: number }>().statusCode;
        return {
          isSuccess: true,
          code: 'COMMON' + status,
          message: '요청에 성공했습니다.',
          result: result ?? null,
        };
      }),
    );
  }
}

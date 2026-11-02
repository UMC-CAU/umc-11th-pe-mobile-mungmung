import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import { QueryFailedError } from 'typeorm';
import type { Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    const duplicate =
      exception instanceof QueryFailedError &&
      (exception.driverError as { code?: string }).code === 'ER_DUP_ENTRY';
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : duplicate
          ? 409
          : 500;
    const body =
      exception instanceof HttpException ? exception.getResponse() : null;
    const message =
      typeof body === 'string'
        ? body
        : body
          ? (body as { message?: string | string[] }).message
          : duplicate
            ? '이미 등록된 회원 또는 평점입니다.'
            : '서버 오류가 발생했습니다.';
    if (status === 500) this.logger.error(exception);
    response.status(status).json({
      isSuccess: false,
      code: 'COMMON' + status,
      message: Array.isArray(message)
        ? message[0]
        : (message ?? '요청에 실패했습니다.'),
      result: null,
    });
  }
}

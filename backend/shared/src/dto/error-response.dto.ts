export class ErrorResponseDto {
  error: {
    code: string;
    message: string;
    status: number;
    details?: Array<{ field: string; message: string }>;
    request_id?: string;
    timestamp: string;
  };

  static create(
    code: string,
    message: string,
    status: number,
    details?: Array<{ field: string; message: string }>,
    requestId?: string,
  ): ErrorResponseDto {
    return {
      error: {
        code,
        message,
        status,
        details,
        request_id: requestId,
        timestamp: new Date().toISOString(),
      },
    };
  }
}

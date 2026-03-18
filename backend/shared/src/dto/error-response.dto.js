"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ErrorResponseDto = void 0;
class ErrorResponseDto {
    static create(code, message, status, details, requestId) {
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
exports.ErrorResponseDto = ErrorResponseDto;
//# sourceMappingURL=error-response.dto.js.map
package com.exception;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.io.IOException;
import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

public final class ApiErrorResponseFactory {

    private ApiErrorResponseFactory() {
    }

    public static ApiErrorResponse build(HttpStatus status,
                                         String errorCode,
                                         String message,
                                         String path,
                                         Map<String, String> fieldErrors,
                                         String traceId) {
        return ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(status.value())
                .error(status.getReasonPhrase())
                .errorCode(errorCode)
                .message(message)
                .path(path)
                .traceId(traceId)
                .fieldErrors(fieldErrors)
                .build();
    }

    public static String newTraceId() {
        return UUID.randomUUID().toString();
    }

    public static void write(HttpServletResponse response,
                             ObjectMapper objectMapper,
                             HttpStatus status,
                             String errorCode,
                             String message,
                             HttpServletRequest request) throws IOException {
        ApiErrorResponse body = build(
                status,
                errorCode,
                message,
                request.getRequestURI(),
                null,
                newTraceId()
        );
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(objectMapper.writeValueAsString(body));
    }
}

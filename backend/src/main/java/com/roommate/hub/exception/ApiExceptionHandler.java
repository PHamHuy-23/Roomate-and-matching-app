package com.roommate.hub.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(ResourceNotFoundException.class)
    ResponseEntity<Map<String, Object>> notFound(ResourceNotFoundException ex) { 
        return response(HttpStatus.NOT_FOUND, ex.getMessage()); 
    }

    @ExceptionHandler(ForbiddenException.class)
    ResponseEntity<Map<String, Object>> forbidden(ForbiddenException ex) { 
        return response(HttpStatus.FORBIDDEN, ex.getMessage()); 
    }

    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<Map<String, Object>> accessDenied(AccessDeniedException ex) {
        return response(HttpStatus.FORBIDDEN, "Bạn không có quyền thực hiện thao tác này");
    }

    @ExceptionHandler(AuthenticationException.class)
    ResponseEntity<Map<String, Object>> authentication(AuthenticationException ex) {
        return response(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập không hợp lệ");
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, Object> body = base(HttpStatus.BAD_REQUEST, "Dữ liệu không hợp lệ");
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fields.put(error.getField(), error.getDefaultMessage());
        }
        body.put("fields", fields);
        return super.handleExceptionInternal(ex, body, headers, status, request);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<Map<String, Object>> unexpected(Exception ex) {
        log.error("Internal server error: ", ex);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, "Đã xảy ra lỗi máy chủ");
    }

    @Override
    protected ResponseEntity<Object> handleExceptionInternal(Exception ex, Object body,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        String message;
        if (status.value() == 500) {
            log.error("Internal server error: ", ex);
            message = "Đã xảy ra lỗi máy chủ";
        } else if (ex instanceof ResponseStatusException statusException
                && statusException.getReason() != null && !statusException.getReason().isBlank()) {
            message = statusException.getReason();
        } else if (ex instanceof HttpMessageNotReadableException) {
            message = "Dữ liệu JSON hoặc định dạng ngày không hợp lệ";
        } else if (ex instanceof MissingServletRequestParameterException missing) {
            message = "Thiếu tham số bắt buộc: " + missing.getParameterName();
        } else {
            message = frameworkMessage(status);
        }
        // Let Spring preserve status, headers (e.g. Allow on 405) and committed-response handling.
        return super.handleExceptionInternal(ex, base(status, message), headers, status, request);
    }

    private String frameworkMessage(HttpStatusCode status) {
        return switch (status.value()) {
            case 400 -> "Tham số hoặc dữ liệu không hợp lệ";
            case 404 -> "Không tìm thấy tài nguyên";
            case 405 -> "Phương thức HTTP không được hỗ trợ";
            case 406 -> "Định dạng phản hồi không được hỗ trợ";
            case 413 -> "Dữ liệu gửi lên vượt quá giới hạn";
            case 415 -> "Định dạng dữ liệu gửi lên không được hỗ trợ";
            case 503 -> "Dịch vụ tạm thời không khả dụng";
            default -> "Không thể xử lý yêu cầu";
        };
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<Map<String, Object>> badRequest(IllegalArgumentException ex) {
        return response(HttpStatus.BAD_REQUEST, ex.getMessage());
    }

    private ResponseEntity<Map<String, Object>> response(HttpStatus status, String message) { 
        return ResponseEntity.status(status).body(base(status, message)); 
    }

    private Map<String, Object> base(HttpStatusCode status, String message) {
        Map<String, Object> body = new LinkedHashMap<>(); 
        body.put("status", status.value()); 
        body.put("message", message); 
        body.put("data", null);
        body.put("timestamp", Instant.now()); 
        return body; 
    }
}

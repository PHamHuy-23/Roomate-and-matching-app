package com.roommate.hub.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(ResourceNotFoundException.class)
    ResponseEntity<Map<String, Object>> notFound(ResourceNotFoundException ex) { 
        return response(HttpStatus.NOT_FOUND, ex.getMessage()); 
    }

    @ExceptionHandler(ForbiddenException.class)
    ResponseEntity<Map<String, Object>> forbidden(ForbiddenException ex) { 
        return response(HttpStatus.FORBIDDEN, ex.getMessage()); 
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<Map<String, Object>> validation(MethodArgumentNotValidException ex) {
        Map<String, Object> body = base(HttpStatus.BAD_REQUEST, "Dữ liệu không hợp lệ");
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fields.put(error.getField(), error.getDefaultMessage());
        }
        body.put("fields", fields);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(ResponseStatusException.class)
    ResponseEntity<Map<String, Object>> status(ResponseStatusException ex) { 
        return response(HttpStatus.valueOf(ex.getStatusCode().value()), ex.getReason()); 
    }

    @ExceptionHandler(RuntimeException.class)
    ResponseEntity<Map<String, Object>> runtime(RuntimeException ex) { 
        log.error("Internal server error: ", ex);
        String msg = ex.getMessage() != null && !ex.getMessage().isBlank() ? ex.getMessage() : "Đã xảy ra lỗi máy chủ";
        return response(HttpStatus.INTERNAL_SERVER_ERROR, msg); 
    }

    private ResponseEntity<Map<String, Object>> response(HttpStatus status, String message) { 
        return ResponseEntity.status(status).body(base(status, message)); 
    }

    private Map<String, Object> base(HttpStatus status, String message) { 
        Map<String, Object> body = new LinkedHashMap<>(); 
        body.put("status", status.value()); 
        body.put("message", message); 
        body.put("timestamp", Instant.now()); 
        return body; 
    }
}

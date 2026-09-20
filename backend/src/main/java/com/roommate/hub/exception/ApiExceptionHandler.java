package com.roommate.hub.exception;

import org.springframework.http.*;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    ResponseEntity<Map<String, Object>> notFound(ResourceNotFoundException ex) { return response(HttpStatus.NOT_FOUND, ex.getMessage()); }
    @ExceptionHandler(ForbiddenException.class)
    ResponseEntity<Map<String, Object>> forbidden(ForbiddenException ex) { return response(HttpStatus.FORBIDDEN, ex.getMessage()); }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<Map<String, Object>> validation(MethodArgumentNotValidException ex) {
        Map<String, Object> body = base(HttpStatus.BAD_REQUEST, "Dữ liệu không hợp lệ");
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) fields.put(error.getField(), error.getDefaultMessage());
        body.put("fields", fields);
        return ResponseEntity.badRequest().body(body);
    }
    @ExceptionHandler(RuntimeException.class)
    ResponseEntity<Map<String, Object>> runtime(RuntimeException ex) { return response(HttpStatus.BAD_REQUEST, ex.getMessage()); }
    private ResponseEntity<Map<String, Object>> response(HttpStatus status, String message) { return ResponseEntity.status(status).body(base(status, message)); }
    private Map<String, Object> base(HttpStatus status, String message) { Map<String, Object> body = new LinkedHashMap<>(); body.put("status", status.value()); body.put("message", message); body.put("timestamp", Instant.now()); return body; }
}

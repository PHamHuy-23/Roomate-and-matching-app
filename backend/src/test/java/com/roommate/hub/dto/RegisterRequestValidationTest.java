package com.roommate.hub.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.util.Set;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

class RegisterRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void requiresBirthDateAndUniversity() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("new.user@example.com");
        request.setPassword("123456");
        request.setFullName("Người dùng mới");
        request.setGender("MALE");

        Set<String> invalidFields = validator.validate(request).stream()
                .map(violation -> violation.getPropertyPath().toString())
                .collect(Collectors.toSet());

        assertThat(invalidFields).contains("birthDate", "university");
    }
}

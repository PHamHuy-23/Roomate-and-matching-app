package com.roommate.hub.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class NewPasswordValidator implements ConstraintValidator<NewPassword, String> {
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        String error = PasswordPolicy.error(value);
        if (error == null) return true;
        context.disableDefaultConstraintViolation();
        context.buildConstraintViolationWithTemplate(error).addConstraintViolation();
        return false;
    }
}

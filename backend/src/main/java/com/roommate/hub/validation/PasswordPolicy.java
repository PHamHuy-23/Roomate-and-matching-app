package com.roommate.hub.validation;

import java.nio.charset.StandardCharsets;

/** Rules for newly created passwords only; existing passwords remain usable for login. */
public final class PasswordPolicy {
    public static final int MIN_LENGTH = 8;
    public static final int MAX_UTF8_BYTES = 72;

    private PasswordPolicy() {}

    public static String error(String password) {
        if (password == null || password.isBlank()) {
            return "Mật khẩu không được để trống";
        }
        if (password.length() < MIN_LENGTH) {
            return "Mật khẩu phải có ít nhất 8 ký tự";
        }
        if (password.getBytes(StandardCharsets.UTF_8).length > MAX_UTF8_BYTES) {
            return "Mật khẩu không được vượt quá 72 byte UTF-8";
        }
        return null;
    }

    public static void requireValid(String password) {
        String error = error(password);
        if (error != null) throw new IllegalArgumentException(error);
    }
}

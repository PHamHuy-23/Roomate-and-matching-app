package com.roommate.hub.validation;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PasswordPolicyTest {
    @ParameterizedTest @NullSource @ValueSource(strings = {"", "        ", "1234567"})
    void rejectsMissingBlankOrShortPassword(String value) {
        assertThat(PasswordPolicy.error(value)).isNotNull();
        assertThatThrownBy(() -> PasswordPolicy.requireValid(value)).isInstanceOf(IllegalArgumentException.class);
    }
    @Test void acceptsEightCharactersAndExactly72Utf8BytesWithoutTrimming() {
        for (String password : new String[]{"12345678", "a".repeat(72), "ắ".repeat(24), " 123456 "}) {
            assertThat(PasswordPolicy.error(password)).isNull();
        }
    }
    @Test void rejectsMoreThan72BytesEvenWhenCharacterCountFits() {
        assertThat(PasswordPolicy.error("a".repeat(73))).contains("72 byte");
        assertThat(PasswordPolicy.error("ắ".repeat(25))).contains("72 byte");
        assertThat(PasswordPolicy.error("😀".repeat(19))).contains("72 byte");
    }
}

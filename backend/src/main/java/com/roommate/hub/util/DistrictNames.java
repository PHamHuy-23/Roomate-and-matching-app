package com.roommate.hub.util;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;

/** Compatibility names from the app's existing HCMC district catalogue, not geocoding. */
public final class DistrictNames {
    private static final List<String> KEYS = List.of("Thu Duc", "Quan 1", "Quan 3", "Quan 4",
            "Quan 5", "Quan 6", "Quan 7", "Quan 8", "Quan 10", "Quan 11", "Quan 12",
            "Binh Thanh", "Go Vap", "Phu Nhuan", "Tan Binh", "Tan Phu", "Binh Tan",
            "Binh Chanh", "Hoc Mon", "Nha Be");

    private DistrictNames() {}

    public static String canonical(String value) {
        if (value == null) return null;
        String trimmed = value.replaceAll("(?U)\\s+", " ").strip();
        String comparable = fold(trimmed).replaceAll("[^a-z0-9]+", " ").strip()
                .replaceFirst("\\s+(?:(?:tp|thanh pho)\\s+)?(?:hcm|ho chi minh)$", "")
                .replaceFirst("^(?:tp|thanh pho|huyen)\\s+", "")
                .replaceFirst("^(?:q|quan)\\s*(\\d+)$", "quan $1");
        // Named districts may be prefixed with 'Quận'; numbered districts keep it.
        if (!comparable.matches("quan \\d+")) comparable = comparable.replaceFirst("^quan\\s+", "");
        for (String key : KEYS) {
            if (fold(key).equals(comparable)) return key;
        }
        // Never turn unrecognized data into a different known district.
        return trimmed;
    }

    public static boolean same(String left, String right) {
        String a = canonical(left);
        String b = canonical(right);
        return a != null && b != null && !a.isBlank() && !b.isBlank() && fold(a).equals(fold(b));
    }

    private static String fold(String value) {
        return Normalizer.normalize(value.toLowerCase(Locale.ROOT), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "").replace('đ', 'd');
    }
}

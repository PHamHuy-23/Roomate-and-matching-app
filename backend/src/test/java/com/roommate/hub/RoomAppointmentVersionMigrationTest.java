package com.roommate.hub;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.FileSystemResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

// H2 PostgreSQL mode smoke check for the actual migration; not a production PostgreSQL certification.
class RoomAppointmentVersionMigrationTest {
    @Test void migrationAddsVersionsKeepsRowsAndNeverResetsExistingVersionsOnRerun() throws Exception {
        try (var connection = DriverManager.getConnection("jdbc:h2:mem:migration_" + UUID.randomUUID() + ";MODE=PostgreSQL")) {
            var migration = new FileSystemResource("../database/migrations/20261005_room_appointment_versions.sql");
            try (var sql = connection.createStatement()) {
                sql.execute("CREATE TABLE room_posts(id BIGINT PRIMARY KEY, title VARCHAR(200), version BIGINT)");
                sql.execute("INSERT INTO room_posts VALUES (1, 'Keep edited content', 8), (2, 'Keep legacy content', NULL)");
                sql.execute("CREATE TABLE viewing_appointments(id BIGINT PRIMARY KEY, status VARCHAR(20))");
                sql.execute("INSERT INTO viewing_appointments VALUES (1, 'CANCELLED')");
                ScriptUtils.executeSqlScript(connection, migration);
                sql.execute("UPDATE viewing_appointments SET version = 3 WHERE id = 1");
                ScriptUtils.executeSqlScript(connection, migration);
                try (var rows = sql.executeQuery("SELECT title, version FROM room_posts ORDER BY id")) {
                    assertThat(rows.next()).isTrue();
                    assertThat(rows.getString(1)).isEqualTo("Keep edited content");
                    assertThat(rows.getLong(2)).isEqualTo(8);
                    assertThat(rows.next()).isTrue();
                    assertThat(rows.getString(1)).isEqualTo("Keep legacy content");
                    assertThat(rows.getLong(2)).isZero();
                    assertThat(rows.next()).isFalse();
                }
                try (var rows = sql.executeQuery("SELECT status, version FROM viewing_appointments WHERE id = 1")) {
                    assertThat(rows.next()).isTrue();
                    assertThat(rows.getString(1)).isEqualTo("CANCELLED");
                    assertThat(rows.getLong(2)).isEqualTo(3);
                }
                sql.execute("INSERT INTO viewing_appointments(id, status) VALUES (2, 'PENDING')");
                try (var rows = sql.executeQuery("SELECT version FROM viewing_appointments WHERE id = 2")) {
                    assertThat(rows.next()).isTrue();
                    assertThat(rows.getLong(1)).isZero();
                    assertThat(rows.wasNull()).isFalse();
                }
                assertThatThrownBy(() -> sql.execute("UPDATE room_posts SET version = NULL WHERE id = 1"))
                        .isInstanceOf(SQLException.class);
                assertThatThrownBy(() -> sql.execute("UPDATE viewing_appointments SET version = NULL WHERE id = 1"))
                        .isInstanceOf(SQLException.class);
            }
        }
    }
}

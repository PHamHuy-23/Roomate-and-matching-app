package com.roommate.hub;

import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.FileSystemResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.UUID;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.*;

/** Executes the checked-in SQL against isolated H2 databases in PostgreSQL mode.
 * This does not replace verifying the migration on a real PostgreSQL instance. */
class MatchRequestVersionMigrationTest {
    private static final Path DATABASE = Path.of(System.getProperty("basedir", "."), "..", "database");
    private static final Path MIGRATION = DATABASE.resolve("migrations/20261001_match_request_version.sql");

    @Test void missingColumnIsAddedWithoutLosingExistingRequests() throws Exception {
        try (Connection connection = database()) {
            legacyTable(connection, false);
            execute(connection, "INSERT INTO match_requests VALUES (1, 11, 22, 85.5, 'PENDING')");

            migrate(connection);
            assertRequest(connection, 1, 0, "PENDING");
            assertDefaultAndNotNull(connection);

            execute(connection, "UPDATE match_requests SET version = 4 WHERE id = 1");
            migrate(connection);
            assertRequest(connection, 1, 4, "PENDING");
        }
    }

    @Test void nullVersionsAreBackfilledAndExistingVersionsArePreservedOnRerun() throws Exception {
        try (Connection connection = database()) {
            legacyTable(connection, true);
            execute(connection, "INSERT INTO match_requests VALUES (1, 11, 22, 85.5, 'PENDING', NULL)");
            execute(connection, "INSERT INTO match_requests VALUES (2, 11, 22, 85.5, 'ACCEPTED', 7)");

            migrate(connection);
            migrate(connection);
            assertRequest(connection, 1, 0, "PENDING");
            assertRequest(connection, 2, 7, "ACCEPTED");
            assertDefaultAndNotNull(connection);
        }
    }

    @Test void freshSchemaHasTheSameVersionDefaultAndConstraint() throws Exception {
        try (Connection connection = database()) {
            // H2 uses a different spelling for this PostgreSQL timestamp type.
            execute(connection, "CREATE DOMAIN TIMESTAMPTZ AS TIMESTAMP WITH TIME ZONE");
            execute(connection, "CREATE TABLE users (id BIGINT PRIMARY KEY)");
            execute(connection, "INSERT INTO users VALUES (11), (22)");
            var matchTable = Pattern.compile("CREATE TABLE match_requests \\(.*?\\n\\);", Pattern.DOTALL)
                    .matcher(Files.readString(DATABASE.resolve("01_schema.sql")));
            assertThat(matchTable.find()).as("match_requests DDL in baseline schema").isTrue();
            execute(connection, matchTable.group());

            assertDefaultAndNotNull(connection);
            migrate(connection);
            assertRequest(connection, 99, 0, "PENDING");
        }
    }

    private Connection database() throws SQLException {
        JdbcDataSource dataSource = new JdbcDataSource();
        dataSource.setURL("jdbc:h2:mem:version_" + UUID.randomUUID()
                + ";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE");
        dataSource.setUser("sa");
        return dataSource.getConnection();
    }

    private void legacyTable(Connection connection, boolean nullableVersion) throws SQLException {
        execute(connection, "CREATE TABLE match_requests (id BIGINT PRIMARY KEY, sender_id BIGINT NOT NULL, "
                + "receiver_id BIGINT NOT NULL, match_score DOUBLE PRECISION NOT NULL, status VARCHAR(20) NOT NULL"
                + (nullableVersion ? ", version BIGINT" : "") + ")");
    }

    private void migrate(Connection connection) {
        ScriptUtils.executeSqlScript(connection, new FileSystemResource(MIGRATION));
    }

    private void assertDefaultAndNotNull(Connection connection) throws SQLException {
        execute(connection, "INSERT INTO match_requests (id, sender_id, receiver_id, match_score, status) "
                + "VALUES (99, 11, 22, 85.5, 'PENDING')");
        assertRequest(connection, 99, 0, "PENDING");
        assertThatThrownBy(() -> execute(connection, "UPDATE match_requests SET version = NULL WHERE id = 99"))
                .isInstanceOf(SQLException.class);
    }

    private void assertRequest(Connection connection, long id, long version, String status) throws SQLException {
        try (var statement = connection.prepareStatement("SELECT * FROM match_requests WHERE id = ?")) {
            statement.setLong(1, id);
            try (var row = statement.executeQuery()) {
                assertThat(row.next()).isTrue();
                assertThat(row.getLong("sender_id")).isEqualTo(11);
                assertThat(row.getLong("receiver_id")).isEqualTo(22);
                assertThat(row.getDouble("match_score")).isEqualTo(85.5);
                assertThat(row.getString("status")).isEqualTo(status);
                assertThat(row.getLong("version")).isEqualTo(version);
                assertThat(row.wasNull()).isFalse();
                assertThat(row.next()).isFalse();
            }
        }
    }

    private void execute(Connection connection, String sql) throws SQLException {
        try (var statement = connection.createStatement()) {
            statement.execute(sql);
        }
    }
}

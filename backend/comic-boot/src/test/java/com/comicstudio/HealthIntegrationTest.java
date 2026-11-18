package com.comicstudio;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = "comic.internal-token=test-internal-token-not-real")
@AutoConfigureMockMvc
class HealthIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Test void publicHealth() throws Exception {
        mvc.perform(get("/api/v1/health")).andExpect(status().isOk())
           .andExpect(jsonPath("$.code").value("OK"))
           .andExpect(jsonPath("$.data.status").value("UP"))
           .andExpect(jsonPath("$.data.service").value("backend"));
    }
    @Test void internalHealthWithValidToken() throws Exception {
        mvc.perform(get("/internal/v1/health").header("Authorization", "Bearer test-internal-token-not-real"))
           .andExpect(status().isOk()).andExpect(jsonPath("$.code").value("OK"));
    }
    @Test void missingToken() throws Exception {
        mvc.perform(get("/internal/v1/health")).andExpect(status().isUnauthorized())
           .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }
    @Test void wrongToken() throws Exception {
        mvc.perform(get("/internal/v1/health").header("Authorization", "Bearer wrong"))
           .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.data").isEmpty());
    }
    @Test void internalUnknownRouteIsProtected() throws Exception {
        mvc.perform(get("/internal/v1/executions")).andExpect(status().isUnauthorized());
    }
    @Test void flywayRanOnPostgres17() {
        assertThat(jdbc.queryForObject("SHOW server_version", String.class)).startsWith("17.");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM flyway_schema_history WHERE success=true AND version='1'", Integer.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT version FROM platform_baseline WHERE id=1", String.class)).isEqualTo("P0");
    }
}

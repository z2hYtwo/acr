package com.comicstudio.health;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
@Service
public class HealthService {
    private final JdbcTemplate jdbc;
    public HealthService(JdbcTemplate jdbc) { this.jdbc = jdbc; }
    public void checkDatabase() { jdbc.queryForObject("SELECT 1", Integer.class); }
}

package com.comicstudio.health;
import com.comicstudio.common.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
@RestController
public class HealthController {
    private final HealthService service;
    public HealthController(HealthService service) { this.service = service; }
    public record HealthData(String service, String status) {}
    @GetMapping({"/api/v1/health", "/internal/v1/health"})
    public ApiResponse<HealthData> health() {
        service.checkDatabase();
        return ApiResponse.ok(new HealthData("backend", "UP"));
    }
}

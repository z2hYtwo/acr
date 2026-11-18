package com.comicstudio.health;
import com.comicstudio.common.ApiResponse;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
@RestControllerAdvice
public class HealthExceptionHandler {
    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ApiResponse<Void>> databaseUnavailable(DataAccessException ex) {
        return ResponseEntity.status(503).body(ApiResponse.error("SERVICE_UNAVAILABLE", "Database unavailable"));
    }
}

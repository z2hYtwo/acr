package com.comicstudio.config;
import com.comicstudio.common.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
@Component
public class InternalAuthFilter extends OncePerRequestFilter {
    private final byte[] expected;
    private final ObjectMapper mapper;
    public InternalAuthFilter(@Value("${comic.internal-token}") String token, ObjectMapper mapper) {
        if (token.isBlank()) throw new IllegalArgumentException("Internal token must not be blank");
        this.expected = ("Bearer " + token).getBytes(StandardCharsets.UTF_8);
        this.mapper = mapper;
    }
    @Override protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain) throws ServletException, IOException {
        if (req.getRequestURI().startsWith("/internal/")) {
            String header = req.getHeader("Authorization");
            if (header == null || !MessageDigest.isEqual(expected, header.getBytes(StandardCharsets.UTF_8))) {
                res.setStatus(401); res.setContentType("application/json"); res.setCharacterEncoding("UTF-8");
                res.setHeader("WWW-Authenticate", "Bearer");
                mapper.writeValue(res.getWriter(), ApiResponse.error("UNAUTHORIZED", "Internal authentication required"));
                return;
            }
        }
        chain.doFilter(req, res);
    }
}

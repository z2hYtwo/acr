package com.comicstudio.health;
import jakarta.persistence.*;
import java.time.Instant;
@Entity
@Table(name="platform_baseline")
public class PlatformBaseline {
    @Id private Integer id;
    @Column(nullable=false, length=16) private String version;
    @Column(name="created_at", nullable=false) private Instant createdAt;
    protected PlatformBaseline() {}
}

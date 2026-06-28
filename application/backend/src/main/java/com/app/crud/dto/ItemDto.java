package com.app.crud.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDateTime;

public class ItemDto {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Request {
        @NotBlank(message = "Name is required")
        @Size(min = 1, max = 100)
        private String name;

        @Size(max = 500)
        private String description;

        @NotNull(message = "Quantity is required")
        @Min(0)
        private Integer quantity;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Long id;
        private String name;
        private String description;
        private Integer quantity;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
    }
}

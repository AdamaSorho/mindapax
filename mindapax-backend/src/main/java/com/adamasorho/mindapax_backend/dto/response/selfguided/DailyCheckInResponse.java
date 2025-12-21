package com.adamasorho.mindapax_backend.dto.response.selfguided;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.DailyCheckIn;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailyCheckInResponse {
    private LocalDate date;
    private int mood;
    private int effort;
    private String note;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static DailyCheckInResponse fromEntity(DailyCheckIn entry) {
        if (entry == null) return null;
        return new DailyCheckInResponse(
            entry.getDate(),
            entry.getMood(),
            entry.getEffort(),
            entry.getNote(),
            entry.getCreatedAt(),
            entry.getUpdatedAt()
        );
    }
}

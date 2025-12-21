package com.adamasorho.mindapax_backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailyCheckInRequest {
    private Integer mood;
    private Integer effort;
    private String note;
}

package com.adamasorho.mindapax_backend.dto.subscription;

import com.adamasorho.mindapax_backend.model.enums.BillingCycle;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlanDTO {
    private Long id;
    private String name;
    private Double price;
    private String currency;
    private BillingCycle billingCycle;
    private String description;
    private boolean active;
    private Integer sessionAllowance;
    private List<String> features;
}

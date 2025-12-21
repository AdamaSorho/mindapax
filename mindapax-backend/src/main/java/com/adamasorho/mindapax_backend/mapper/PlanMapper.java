package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import com.adamasorho.mindapax_backend.dto.subscription.PlanDTO;
import com.adamasorho.mindapax_backend.model.Plan;

@Mapper(componentModel = "spring")
public interface PlanMapper {
    @Mapping(target = "eligibleForTrial", ignore = true)
    @Mapping(target = "requiresPayment", ignore = true)
    PlanDTO toDTO(Plan plan);
    Plan toEntity(PlanDTO dto);
}

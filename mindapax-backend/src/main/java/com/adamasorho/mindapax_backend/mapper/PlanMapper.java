package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import com.adamasorho.mindapax_backend.dto.subscription.PlanDTO;
import com.adamasorho.mindapax_backend.model.Plan;

@Mapper(componentModel = "spring")
public interface PlanMapper {
    PlanDTO toDTO(Plan plan);
    Plan toEntity(PlanDTO dto);
}


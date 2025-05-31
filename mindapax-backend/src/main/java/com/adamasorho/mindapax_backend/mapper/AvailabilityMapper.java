package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.request.AvailabilityRequest;
import com.adamasorho.mindapax_backend.dto.response.AvailabilityResponse;
import com.adamasorho.mindapax_backend.model.Availability;

@Mapper(componentModel = "spring")
public interface AvailabilityMapper {
  @Mappings({
    @Mapping(target = "professional", ignore = true),
    @Mapping(target = "id", ignore = true)
  })
  Availability toEntity(AvailabilityRequest availabilityRequest);

  @Mappings({
    @Mapping(target = "professionalId", source = "professional.id")
  })
  AvailabilityResponse toResponse(Availability availability);
}

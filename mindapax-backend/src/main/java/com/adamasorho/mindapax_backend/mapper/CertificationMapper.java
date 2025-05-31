package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.CertificationDTO;
import com.adamasorho.mindapax_backend.model.Certification;

@Mapper(componentModel = "spring")
public interface CertificationMapper {
  @Mappings({
    @Mapping(target = "name", source = "fileName")
  })
  CertificationDTO toDTO(Certification certification);

  @Mappings({
    @Mapping(target = "fileName", source = "name"),
    @Mapping(target = "professional", ignore = true)
  })
  Certification toEntity(CertificationDTO certificationDTO);
}

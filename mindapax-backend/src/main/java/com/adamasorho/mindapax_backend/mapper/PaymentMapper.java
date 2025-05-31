package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.PaymentDTO;
import com.adamasorho.mindapax_backend.model.Payment;

@Mapper(componentModel = "spring")
public interface PaymentMapper {
  @Mappings({
    @Mapping(target = "userId", source = "user.id")
  })
  PaymentDTO toDTO(Payment payment);

  @Mappings({
    @Mapping(target = "user", ignore = true)
  })
  Payment toEntity(PaymentDTO paymentDTO);
}

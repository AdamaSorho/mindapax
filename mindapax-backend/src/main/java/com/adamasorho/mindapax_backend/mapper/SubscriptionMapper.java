package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.subscription.SubscriptionDTO;
import com.adamasorho.mindapax_backend.model.Subscription;

@Mapper(componentModel = "spring")
public interface SubscriptionMapper {
    @Mappings({
        @Mapping(target = "planId", source = "plan.id"),
        @Mapping(target = "planName", source = "plan.name"),
        @Mapping(target = "planPrice", source = "plan.price"),
        @Mapping(target = "planCurrency", source = "plan.currency"),
        @Mapping(target = "lastPaymentId", source = "lastPayment.id")
    })
    SubscriptionDTO toDTO(Subscription sub);
}


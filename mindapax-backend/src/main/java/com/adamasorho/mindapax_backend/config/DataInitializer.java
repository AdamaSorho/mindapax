package com.adamasorho.mindapax_backend.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.adamasorho.mindapax_backend.model.Plan;
import com.adamasorho.mindapax_backend.model.enums.BillingCycle;
import com.adamasorho.mindapax_backend.repository.PlanRepository;

@Configuration
public class DataInitializer {
    @Bean
    CommandLineRunner seedPlans(PlanRepository planRepo) {
        return args -> {
            if (planRepo.count() > 0) return;
            Plan basic = new Plan();
            basic.setName("Basic");
            basic.setPrice(10000.0);
            basic.setCurrency("XOF");
            basic.setBillingCycle(BillingCycle.MONTHLY);
            basic.setSessionAllowance(1);
            basic.setDescription("1 session per month");
            basic.getFeatures().addAll(java.util.List.of(
                "AI Assistant with personalized context",
                "Goal recommendations and tracking",
                "Session scheduling",
                "Secure billing & subscriptions",
                "1 session per cycle"
            ));
            planRepo.save(basic);

            Plan standard = new Plan();
            standard.setName("Standard");
            standard.setPrice(25000.0);
            standard.setCurrency("XOF");
            standard.setBillingCycle(BillingCycle.MONTHLY);
            standard.setSessionAllowance(3);
            standard.setDescription("3 sessions per month");
            standard.getFeatures().addAll(java.util.List.of(
                "AI Assistant with personalized context",
                "Goal recommendations and tracking",
                "Session scheduling",
                "Priority booking",
                "Secure billing & subscriptions",
                "3 sessions per cycle"
            ));
            planRepo.save(standard);

            Plan premium = new Plan();
            premium.setName("Premium");
            premium.setPrice(50000.0);
            premium.setCurrency("XOF");
            premium.setBillingCycle(BillingCycle.MONTHLY);
            premium.setSessionAllowance(8);
            premium.setDescription("8 sessions per month");
            premium.getFeatures().addAll(java.util.List.of(
                "AI Assistant with personalized context",
                "Goal recommendations and tracking",
                "Session scheduling",
                "Priority booking",
                "Advanced progress insights",
                "Secure billing & subscriptions",
                "8 sessions per cycle"
            ));
            planRepo.save(premium);
        };
    }
}

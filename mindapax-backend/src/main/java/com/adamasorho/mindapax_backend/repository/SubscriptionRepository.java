package com.adamasorho.mindapax_backend.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import com.adamasorho.mindapax_backend.model.Subscription;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.Payment;
import com.adamasorho.mindapax_backend.model.enums.SubscriptionStatus;

public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {
    List<Subscription> findByUserOrderByIdDesc(User user);
    Optional<Subscription> findByLastPayment(Payment payment);
    List<Subscription> findByUserAndStatusOrderByIdDesc(User user, SubscriptionStatus status);
}

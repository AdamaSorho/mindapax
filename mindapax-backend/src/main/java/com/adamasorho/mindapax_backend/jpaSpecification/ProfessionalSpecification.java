package com.adamasorho.mindapax_backend.jpaSpecification;

import java.time.LocalDate;

import org.springframework.data.jpa.domain.Specification;

import com.adamasorho.mindapax_backend.model.Availability;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;

import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;

public class ProfessionalSpecification {

  public static Specification<Professional> hasFirstName(String firstName) {
      return (root, query, cb) -> firstName == null ? null :
              cb.like(cb.lower(root.get("user").get("firstName")), "%" + firstName.toLowerCase() + "%");
  }

  public static Specification<Professional> hasLastName(String lastName) {
      return (root, query, cb) -> lastName == null ? null :
              cb.like(cb.lower(root.get("user").get("lastName")), "%" + lastName.toLowerCase() + "%");
  }

  public static Specification<Professional> hasSpecialization(Specialization specialization) {
      return (root, query, cb) -> specialization == null ? null :
              cb.equal(root.get("specialization"), specialization);
  }

  public static Specification<Professional> hasExperienceGreaterThanOrEqual(Integer years) {
      return (root, query, cb) -> years == null ? null :
              cb.greaterThanOrEqualTo(root.get("yearsOfExperience"), years); // assuming experience is on User
  }

  public static Specification<Professional> isAvailableOn(LocalDate date) {
      return (root, query, cb) -> {
          if (date == null) return null;
          Join<Professional, Availability> availability = root.join("availabilities", JoinType.LEFT);
          return cb.equal(availability.get("date"), date);
      };
  }

  public static Specification<Professional> hasStatus(ProfessionalStatus status) {
      return (root, query, cb) -> status == null ? null : cb.equal(root.get("status"), status);
  }
}


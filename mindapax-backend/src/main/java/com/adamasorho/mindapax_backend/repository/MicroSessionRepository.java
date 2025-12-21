package com.adamasorho.mindapax_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.MicroSession;

public interface MicroSessionRepository extends JpaRepository<MicroSession, Long> {}

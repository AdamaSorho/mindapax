package com.adamasorho.mindapax_backend.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.adamasorho.mindapax_backend.model.MicroSession;
import com.adamasorho.mindapax_backend.model.Plan;
import com.adamasorho.mindapax_backend.model.enums.BillingCycle;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;
import com.adamasorho.mindapax_backend.repository.MicroSessionRepository;
import com.adamasorho.mindapax_backend.repository.PlanRepository;

@Configuration
public class DataInitializer {
    @Bean
    CommandLineRunner seedPlans(PlanRepository planRepo) {
        return args -> {
            if (planRepo.count() == 0) {
                Plan basic = new Plan();
                basic.setName("Basic");
                basic.setPrice(10000.0);
                basic.setCurrency("XOF");
                basic.setBillingCycle(BillingCycle.MONTHLY);
                basic.setSessionAllowance(1);
                basic.setDescription("1 session per month");
                basic.setTrial(false);
                basic.setTrialDurationDays(null);
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
                standard.setTrial(false);
                standard.setTrialDurationDays(null);
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
                premium.setTrial(false);
                premium.setTrialDurationDays(null);
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
            }

            planRepo.findByNameIgnoreCase("Trial").orElseGet(() -> {
                Plan trial = new Plan();
                trial.setName("Trial");
                trial.setPrice(0.0);
                trial.setCurrency("XOF");
                trial.setBillingCycle(BillingCycle.MONTHLY);
                trial.setSessionAllowance(1);
                trial.setDescription("Enjoy every feature free for 7 days.");
                trial.setTrial(true);
                trial.setTrialDurationDays(7);
                trial.getFeatures().addAll(java.util.List.of(
                    "Unlimited AI assistant access",
                    "Every member feature unlocked",
                    "Schedule and complete at least one session"
                ));
                return planRepo.save(trial);
            });
        };
    }

    @Bean
    CommandLineRunner seedMicroSessions(MicroSessionRepository repo) {
        return args -> {
            if (repo.count() > 0) {
                return;
            }
            repo.saveAll(java.util.List.of(
                build("Clarity journal",
                    "Unclutter your mind and pick one clear next step.",
                    SelfGuidedDomain.MIND,
                    java.util.List.of("Find clarity"),
                    5,
                    java.util.List.of(
                        "Write the biggest thought on your mind.",
                        "List 3 facts that are true right now.",
                        "Write one small next step you can take today."
                    )),
                build("Breathing reset",
                    "Calm your nervous system in a few minutes.",
                    SelfGuidedDomain.MIND,
                    java.util.List.of("Reduce stress"),
                    5,
                    java.util.List.of(
                        "Inhale for 4 seconds.",
                        "Hold for 4 seconds.",
                        "Exhale for 6 seconds.",
                        "Repeat for 10 cycles."
                    )),
                build("Thought reframe",
                    "Shift a limiting thought into a helpful one.",
                    SelfGuidedDomain.MIND,
                    java.util.List.of("Heal emotional patterns"),
                    7,
                    java.util.List.of(
                        "Write the thought that is bothering you.",
                        "Ask: what evidence supports or contradicts it?",
                        "Rewrite the thought in a fair, balanced way."
                    )),
                build("Confidence micro win",
                    "Build confidence through a fast success loop.",
                    SelfGuidedDomain.GROWTH,
                    java.util.List.of("Improve self-confidence"),
                    7,
                    java.util.List.of(
                        "Pick one easy task you can complete in 5 minutes.",
                        "Do it now without overthinking.",
                        "Write one sentence about why it mattered."
                    )),
                build("Focus sprint",
                    "Practice attention and mental discipline.",
                    SelfGuidedDomain.MIND,
                    java.util.List.of("Strengthen mental discipline"),
                    10,
                    java.util.List.of(
                        "Set a 10-minute timer.",
                        "Work on one task with no switching.",
                        "Write one line about what helped you stay focused."
                    )),
                build("5-minute money check",
                    "Stay on top of your spending and savings.",
                    SelfGuidedDomain.MONEY,
                    java.util.List.of("Manage money better"),
                    5,
                    java.util.List.of(
                        "Open your account or budget app.",
                        "Note one expense to reduce this week.",
                        "Move a small amount into savings if possible."
                    )),
                build("Career growth task",
                    "Move forward on a professional goal.",
                    SelfGuidedDomain.MONEY,
                    java.util.List.of("Grow professionally"),
                    10,
                    java.util.List.of(
                        "Update one bullet in your CV or portfolio.",
                        "Write one outreach message or apply to one role.",
                        "Track one new skill to practice next week."
                    )),
                build("Energy boost",
                    "Increase energy with light movement.",
                    SelfGuidedDomain.BODY,
                    java.util.List.of("Improve physical energy", "Build healthy habits"),
                    7,
                    java.util.List.of(
                        "Stand and stretch for 1 minute.",
                        "Walk for 5 minutes.",
                        "Drink a glass of water."
                    )),
                build("Connection ping",
                    "Strengthen a relationship with a small touch.",
                    SelfGuidedDomain.RELATIONSHIPS,
                    java.util.List.of("Build healthier relationships"),
                    5,
                    java.util.List.of(
                        "Think of one person you value.",
                        "Send a short message of appreciation.",
                        "Schedule a time to catch up if needed."
                    )),
                build("Transition grounding",
                    "Reduce uncertainty during change.",
                    SelfGuidedDomain.INTEGRATED,
                    java.util.List.of("Overcome transitions"),
                    8,
                    java.util.List.of(
                        "Write one thing you can control today.",
                        "Name one support you can reach out to.",
                        "Pick one small stabilizing action for tomorrow."
                    )),
                build("Balance scan",
                    "Check your mental, physical, and financial balance.",
                    SelfGuidedDomain.INTEGRATED,
                    java.util.List.of("Live a balanced, intentional life"),
                    10,
                    java.util.List.of(
                        "Rate mind, body, and money from 1 to 5.",
                        "Choose one area to improve this week.",
                        "Write one habit to support that area."
                    ))
            ));
        };
    }

    private MicroSession build(
            String title,
            String description,
            SelfGuidedDomain domain,
            java.util.List<String> outcomes,
            int minutes,
            java.util.List<String> steps) {
        MicroSession session = new MicroSession();
        session.setTitle(title);
        session.setDescription(description);
        session.setDomain(domain);
        session.setOutcomes(new java.util.ArrayList<>(outcomes));
        session.setMinutes(minutes);
        session.setSteps(new java.util.ArrayList<>(steps));
        return session;
    }
}

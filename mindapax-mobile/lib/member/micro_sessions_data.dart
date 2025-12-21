class MicroSession {
  final String id;
  final String title;
  final String description;
  final String domain;
  final List<String> outcomes;
  final int minutes;
  final List<String> steps;

  const MicroSession({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.outcomes,
    required this.minutes,
    required this.steps,
  });

  factory MicroSession.fromJson(Map<String, dynamic> json) {
    return MicroSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      domain: json['domain']?.toString() ?? 'CUSTOM',
      outcomes: ((json['outcomes'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      minutes: (json['minutes'] as num?)?.toInt() ?? 5,
      steps: ((json['steps'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'domain': domain,
      'outcomes': outcomes,
      'minutes': minutes,
      'steps': steps,
    };
  }
}

const List<String> outcomeCategories = [
  'Find clarity',
  'Reduce stress',
  'Improve self-confidence',
  'Heal emotional patterns',
  'Strengthen mental discipline',
  'Manage money better',
  'Grow professionally',
  'Build healthy habits',
  'Improve physical energy',
  'Build healthier relationships',
  'Overcome transitions',
  'Live a balanced, intentional life',
];

const List<MicroSession> microSessions = [
  MicroSession(
    id: 'clarity_journal',
    title: 'Clarity journal',
    description: 'Unclutter your mind and pick one clear next step.',
    domain: 'MIND',
    outcomes: ['Find clarity'],
    minutes: 5,
    steps: [
      'Write the biggest thought on your mind.',
      'List 3 facts that are true right now.',
      'Write one small next step you can take today.',
    ],
  ),
  MicroSession(
    id: 'stress_reset',
    title: 'Breathing reset',
    description: 'Calm your nervous system in a few minutes.',
    domain: 'MIND',
    outcomes: ['Reduce stress'],
    minutes: 5,
    steps: [
      'Inhale for 4 seconds.',
      'Hold for 4 seconds.',
      'Exhale for 6 seconds.',
      'Repeat for 10 cycles.',
    ],
  ),
  MicroSession(
    id: 'reframe',
    title: 'Thought reframe',
    description: 'Shift a limiting thought into a helpful one.',
    domain: 'MIND',
    outcomes: ['Heal emotional patterns'],
    minutes: 7,
    steps: [
      'Write the thought that is bothering you.',
      'Ask: what evidence supports or contradicts it?',
      'Rewrite the thought in a fair, balanced way.',
    ],
  ),
  MicroSession(
    id: 'confidence_win',
    title: 'Confidence micro win',
    description: 'Build confidence through a fast success loop.',
    domain: 'GROWTH',
    outcomes: ['Improve self-confidence'],
    minutes: 7,
    steps: [
      'Pick one easy task you can complete in 5 minutes.',
      'Do it now without overthinking.',
      'Write one sentence about why it mattered.',
    ],
  ),
  MicroSession(
    id: 'focus_sprint',
    title: 'Focus sprint',
    description: 'Practice attention and mental discipline.',
    domain: 'MIND',
    outcomes: ['Strengthen mental discipline'],
    minutes: 10,
    steps: [
      'Set a 10-minute timer.',
      'Work on one task with no switching.',
      'Write one line about what helped you stay focused.',
    ],
  ),
  MicroSession(
    id: 'money_check',
    title: '5-minute money check',
    description: 'Stay on top of your spending and savings.',
    domain: 'MONEY',
    outcomes: ['Manage money better'],
    minutes: 5,
    steps: [
      'Open your account or budget app.',
      'Note one expense to reduce this week.',
      'Move a small amount into savings if possible.',
    ],
  ),
  MicroSession(
    id: 'career_growth',
    title: 'Career growth task',
    description: 'Move forward on a professional goal.',
    domain: 'MONEY',
    outcomes: ['Grow professionally'],
    minutes: 10,
    steps: [
      'Update one bullet in your CV or portfolio.',
      'Write one outreach message or apply to one role.',
      'Track one new skill to practice next week.',
    ],
  ),
  MicroSession(
    id: 'energy_boost',
    title: 'Energy boost',
    description: 'Increase energy with light movement.',
    domain: 'BODY',
    outcomes: ['Improve physical energy', 'Build healthy habits'],
    minutes: 7,
    steps: [
      'Stand and stretch for 1 minute.',
      'Walk for 5 minutes.',
      'Drink a glass of water.',
    ],
  ),
  MicroSession(
    id: 'relationship_ping',
    title: 'Connection ping',
    description: 'Strengthen a relationship with a small touch.',
    domain: 'RELATIONSHIPS',
    outcomes: ['Build healthier relationships'],
    minutes: 5,
    steps: [
      'Think of one person you value.',
      'Send a short message of appreciation.',
      'Schedule a time to catch up if needed.',
    ],
  ),
  MicroSession(
    id: 'transition_grounding',
    title: 'Transition grounding',
    description: 'Reduce uncertainty during change.',
    domain: 'INTEGRATED',
    outcomes: ['Overcome transitions'],
    minutes: 8,
    steps: [
      'Write one thing you can control today.',
      'Name one support you can reach out to.',
      'Pick one small stabilizing action for tomorrow.',
    ],
  ),
  MicroSession(
    id: 'balanced_scan',
    title: 'Balance scan',
    description: 'Check your mental, physical, and financial balance.',
    domain: 'INTEGRATED',
    outcomes: ['Live a balanced, intentional life'],
    minutes: 10,
    steps: [
      'Rate mind, body, and money from 1 to 5.',
      'Choose one area to improve this week.',
      'Write one habit to support that area.',
    ],
  ),
];

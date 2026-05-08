import 'package:flutter/material.dart';

import '../models/template.dart';
import '../theme/app_theme.dart';

/// Bundled default template library — 1:1 port of
/// `frontend/src/data/index.ts` so the app and web ship the same library.
const List<NoteTemplate> kDefaultTemplates = [
  // ── General / Core ─────────────────────────────────────────────────────
  NoteTemplate(
    id: 'soap',
    name: 'SOAP Note',
    description: 'Standard Subjective, Objective, Assessment, Plan format used across all specialties.',
    sections: ['Subjective', 'Objective', 'Assessment', 'Plan', 'Patient Instructions'],
    specialty: 'General',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'progress-notes',
    name: 'Progress Notes',
    description: 'Structured progress note with patient-facing letter summary for ongoing care.',
    sections: ['Subjective', 'Objective', 'Assessment & Plan', 'Letter to Patient'],
    specialty: 'General',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'daily-note',
    name: 'Daily Note',
    description: 'Standardized daily clinical documentation for routine patient encounters.',
    sections: ['Patient Identification', 'Chief Complaint', 'Medical History', 'Current Medications', 'Physical Examination Findings', 'Assessment & Plan'],
    specialty: 'General',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'hpi',
    name: 'HPI Note',
    description: 'Focused History of Present Illness template for comprehensive symptom documentation.',
    sections: ['Identifying Information', 'Chief Complaint', 'History of Present Illness', 'Review of Systems', 'Past Medical History', 'Assessment'],
    specialty: 'General',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'chart-notes',
    name: 'Chart Notes',
    description: 'Concise chart note format for quick clinical documentation and record updates.',
    sections: ['Date & Provider', 'Chief Complaint', 'Clinical Findings', 'Assessment', 'Plan', 'Follow-Up'],
    specialty: 'General',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'chronic-care-management',
    name: 'Chronic Care Management',
    description: 'Comprehensive template for managing patients with chronic conditions.',
    sections: ['Patient Information', 'Care Plan', 'Follow-Up', 'Medications', 'Goals & Education'],
    specialty: 'General',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'wellness-plan',
    name: 'Wellness Plan',
    description: 'Holistic wellness and preventive care planning documentation.',
    sections: ['Health Goals', 'Lifestyle Assessment', 'Nutrition', 'Physical Activity', 'Mental Wellbeing', 'Follow-Up Schedule'],
    specialty: 'General',
    isDefault: true,
  ),

  // ── Psychiatry & Mental Health ─────────────────────────────────────────
  NoteTemplate(
    id: 'psychiatry',
    name: 'Psychiatry Note',
    description: 'Comprehensive psychiatric evaluation and follow-up template.',
    sections: ['Chief Complaint', 'History of Present Illness', 'Mental Status Exam', 'Assessment', 'Plan'],
    specialty: 'Psychiatry',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'psych-eval',
    name: 'Psych Eval',
    description: 'Full psychiatric evaluation including identifying information and risk factors.',
    sections: ['Identifying Information', 'Presenting Problem', 'Diagnosis', 'Mental Status', 'Risk Factors', 'Social History'],
    specialty: 'Psychiatry',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'psychiatric-soap',
    name: 'Psychiatric SOAP Note',
    description: 'SOAP format adapted for psychiatric encounters with MSE and safety assessment.',
    sections: ['Subjective', 'Mental Status Exam', 'Objective', 'Assessment', 'Safety Assessment', 'Plan'],
    specialty: 'Psychiatry',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'mental-health-progress-note',
    name: 'Mental Health Progress Note',
    description: 'Structured progress note for ongoing mental health treatment sessions.',
    sections: ['Client Identification', 'Session Narrative', 'Clinical Observations', 'Interventions', 'Progress Evaluation', 'Plan of Action'],
    specialty: 'Mental Health',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'mental-health-intake',
    name: 'Mental Health Intake Assessment',
    description: 'Comprehensive initial intake assessment for new mental health patients.',
    sections: ['Demographics', 'Presenting Concerns', 'Psychiatric History', 'Substance Use History', 'Family History', 'Social History', 'Mental Status Exam', 'Diagnosis & Treatment Plan'],
    specialty: 'Mental Health',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'mental-health-risk-assessment',
    name: 'Mental Health Risk Assessment',
    description: 'Structured risk evaluation for suicidality, self-harm, and harm to others.',
    sections: ['Risk Factors', 'Protective Factors', 'Suicidal Ideation', 'Self-Harm History', 'Safety Plan', 'Clinician Determination'],
    specialty: 'Mental Health',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'biopsychosocial-assessment',
    name: 'Biopsychosocial Assessment',
    description: 'Comprehensive assessment covering biological, psychological, and social factors.',
    sections: ['Biological Factors', 'Psychological Factors', 'Social Factors', 'Presenting Problem', 'Diagnosis', 'Treatment Recommendations'],
    specialty: 'Mental Health',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'behavioral-health-progress-note',
    name: 'Behavioral Health Progress Note',
    description: 'Progress note tailored for behavioral health and substance use treatment programs.',
    sections: ['Session Information', 'Behavioral Observations', 'Substance Use Update', 'Therapeutic Interventions', 'Response to Treatment', 'Plan'],
    specialty: 'Mental Health',
    isDefault: true,
  ),

  // ── Therapy ────────────────────────────────────────────────────────────
  NoteTemplate(
    id: 'therapy',
    name: 'Therapy Note',
    description: 'Psychotherapy session documentation for individual therapy.',
    sections: ['Session Summary', 'Interventions', 'Client Response', 'Progress', 'Plan'],
    specialty: 'Therapy',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'girp-note',
    name: 'GIRP Note',
    description: 'Goal, Intervention, Response, Plan format for structured therapy documentation.',
    sections: ['Goal', 'Intervention', 'Response', 'Plan'],
    specialty: 'Therapy',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'dbt-diary-card',
    name: 'DBT Diary Card',
    description: 'Dialectical Behavior Therapy diary card for tracking daily emotions and skills use.',
    sections: ['Emotions Tracked', 'Urges & Behaviors', 'Skills Practiced', 'Therapist Notes', 'Goals for Next Session'],
    specialty: 'Mental Health',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'family-therapy-note',
    name: 'Family Therapy Note',
    description: 'Session documentation for family therapy encounters.',
    sections: ['Family Members Present', 'Session Focus', 'Family Dynamics Observed', 'Interventions Used', 'Family Response', 'Plan'],
    specialty: 'Mental Health',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'couples-therapy-note',
    name: 'Couples Therapy Note',
    description: 'Structured documentation for couples therapy sessions.',
    sections: ['Clients Present', 'Session Focus', 'Relational Dynamics', 'Interventions', 'Couple Response', 'Goals & Plan'],
    specialty: 'Mental Health',
    isDefault: true,
  ),

  // ── Physical, Occupational & Speech Therapy ────────────────────────────
  NoteTemplate(
    id: 'physical-therapy-eval',
    name: 'Physical Therapy Evaluation',
    description: 'Initial evaluation form for physical therapy assessment and goal setting.',
    sections: ['Patient Information', 'Medical & Treatment History', 'Assessment Findings', 'Treatment Goals', 'Therapeutic Recommendations', 'Progress Tracking'],
    specialty: 'Physical Therapy',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'occupational-therapy',
    name: 'Occupational Therapy Note',
    description: 'Session documentation for occupational therapy goals and progress.',
    sections: ['Patient Goals', 'Activities Addressed', 'Functional Observations', 'Adaptive Strategies', 'Progress Toward Goals', 'Plan'],
    specialty: 'Occupational Therapy',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'speech-therapy',
    name: 'Speech Therapy Note',
    description: 'Documentation for speech and language therapy sessions and goals.',
    sections: ['Communication Goals', 'Session Activities', 'Articulation & Language Observations', 'Caregiver Education', 'Progress', 'Plan'],
    specialty: 'Speech Therapy',
    isDefault: true,
  ),

  // ── Nursing ────────────────────────────────────────────────────────────
  NoteTemplate(
    id: 'nursing-notes',
    name: 'Nursing Notes',
    description: 'Comprehensive nursing documentation for patient care and clinical observations.',
    sections: ['Patient Assessment', 'Vital Signs', 'Nursing Interventions', 'Medication Administration', 'Patient Response', 'Plan of Care'],
    specialty: 'Nursing',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'nursing-report-sheet',
    name: 'Nursing Report Sheet',
    description: 'Shift handoff report sheet for communicating patient status between nursing staff.',
    sections: ['Patient Demographics', 'Diagnosis & History', 'Current Status', 'Medications', 'Active Orders', 'Handoff Notes'],
    specialty: 'Nursing',
    isDefault: true,
  ),

  // ── Specialty ──────────────────────────────────────────────────────────
  NoteTemplate(
    id: 'pediatrics',
    name: 'Pediatrics Note',
    description: 'Child-focused clinical documentation including growth and development.',
    sections: ['Chief Complaint', 'History', 'Growth & Development', 'Physical Exam', 'Assessment', 'Plan'],
    specialty: 'Pediatrics',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'cardiology',
    name: 'Cardiology Note',
    description: 'Cardiovascular evaluation and follow-up template.',
    sections: ['Chief Complaint', 'Cardiac History', 'Physical Exam', 'ECG/Imaging', 'Assessment', 'Plan'],
    specialty: 'Cardiology',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'dermatology',
    name: 'Dermatology Note',
    description: 'Skin condition examination and treatment documentation.',
    sections: ['Chief Complaint', 'Skin Exam', 'Lesion Description', 'Assessment', 'Plan'],
    specialty: 'Dermatology',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'orthopedics',
    name: 'Orthopedics Note',
    description: 'Musculoskeletal evaluation and treatment template.',
    sections: ['Chief Complaint', 'Mechanism of Injury', 'Physical Exam', 'Imaging', 'Assessment', 'Plan'],
    specialty: 'Orthopedics',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'adime-note',
    name: 'ADIME Note',
    description: 'Assessment, Diagnosis, Intervention, Monitoring & Evaluation format for dietetics.',
    sections: ['Assessment', 'Nutrition Diagnosis', 'Intervention', 'Monitoring & Evaluation'],
    specialty: 'Dietetics',
    isDefault: true,
  ),

  // ── Administrative / Forms ─────────────────────────────────────────────
  NoteTemplate(
    id: 'patient-referral-form',
    name: 'Patient Referral Form',
    description: 'Structured referral documentation to send patients to specialists or services.',
    sections: ['Patient Information', 'Referring Provider', 'Reason for Referral', 'Clinical Summary', 'Additional Notes'],
    specialty: 'Administrative',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'telehealth-consent',
    name: 'Telehealth Consent Form',
    description: 'Informed consent documentation for telehealth and virtual care encounters.',
    sections: ['Patient Information', 'Consent Explanation', 'Risks & Benefits', 'Patient Agreement', 'Provider Signature'],
    specialty: 'Administrative',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'esa-letter',
    name: 'ESA Letter',
    description: 'Emotional Support Animal letter documentation for qualifying patients.',
    sections: ['Patient Information', 'Diagnosis', 'Clinical Justification', 'Provider Information', 'Letter Statement'],
    specialty: 'Mental Health',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'medical-certificate',
    name: 'Medical Certificate',
    description: 'Official medical certificate for work, school, or legal documentation purposes.',
    sections: ['Patient Details', 'Diagnosis / Condition', 'Recommended Rest Period', 'Restrictions', 'Provider Certification'],
    specialty: 'Administrative',
    isDefault: true,
  ),
  NoteTemplate(
    id: 'insurance-claim',
    name: 'Insurance Claim Form',
    description: 'Structured insurance claim documentation for billing and reimbursement.',
    sections: ['Patient Information', 'Insurance Details', 'Diagnosis Codes', 'Procedure Codes', 'Provider Information', 'Claim Statement'],
    specialty: 'Administrative',
    isDefault: true,
  ),

  // ── Custom (placeholder) ───────────────────────────────────────────────
  NoteTemplate(
    id: 'custom',
    name: 'Custom Template',
    description: 'Start from scratch and define your own sections for any specialty or workflow.',
    sections: [],
    specialty: 'Custom',
    isDefault: true,
  ),
];

/// Specialty colour map — mirrors the SPECIALTY_COLORS object on the web
/// (frontend/src/pages/TemplatesPage.tsx:22).
class TemplateSpecialtyColor {
  /// Background tint
  final Color bg;

  /// Foreground (text + icon) accent
  final Color fg;

  /// Border accent
  final Color border;

  const TemplateSpecialtyColor({required this.bg, required this.fg, required this.border});
}

const TemplateSpecialtyColor _slate = TemplateSpecialtyColor(
  bg: Color(0x26475569), // slate-500/15
  fg: Color(0xFFCBD5E1), // slate-300
  border: Color(0x4D475569), // slate-500/30
);

const Map<String, TemplateSpecialtyColor> kSpecialtyColors = {
  'General': TemplateSpecialtyColor(
    bg: Color(0x260EA5E9),
    fg: Color(0xFF7DD3FC),
    border: Color(0x4D0EA5E9),
  ),
  'Psychiatry': TemplateSpecialtyColor(
    bg: Color(0x268B5CF6),
    fg: Color(0xFFC4B5FD),
    border: Color(0x4D8B5CF6),
  ),
  'Mental Health': TemplateSpecialtyColor(
    bg: Color(0x26A855F7),
    fg: Color(0xFFD8B4FE),
    border: Color(0x4DA855F7),
  ),
  'Therapy': TemplateSpecialtyColor(
    bg: Color(0x26EC4899),
    fg: Color(0xFFF9A8D4),
    border: Color(0x4DEC4899),
  ),
  'Physical Therapy': TemplateSpecialtyColor(
    bg: Color(0x26F97316),
    fg: Color(0xFFFDBA74),
    border: Color(0x4DF97316),
  ),
  'Occupational Therapy': TemplateSpecialtyColor(
    bg: Color(0x26F59E0B),
    fg: Color(0xFFFCD34D),
    border: Color(0x4DF59E0B),
  ),
  'Speech Therapy': TemplateSpecialtyColor(
    bg: Color(0x26EAB308),
    fg: Color(0xFFFDE047),
    border: Color(0x4DEAB308),
  ),
  'Nursing': TemplateSpecialtyColor(
    bg: Color(0x2614B8A6),
    fg: Color(0xFF5EEAD4),
    border: Color(0x4D14B8A6),
  ),
  'Pediatrics': TemplateSpecialtyColor(
    bg: Color(0x2622C55E),
    fg: Color(0xFF86EFAC),
    border: Color(0x4D22C55E),
  ),
  'Cardiology': TemplateSpecialtyColor(
    bg: Color(0x26EF4444),
    fg: Color(0xFFFCA5A5),
    border: Color(0x4DEF4444),
  ),
  'Dermatology': TemplateSpecialtyColor(
    bg: Color(0x26F43F5E),
    fg: Color(0xFFFDA4AF),
    border: Color(0x4DF43F5E),
  ),
  'Orthopedics': TemplateSpecialtyColor(
    bg: Color(0x266366F1),
    fg: Color(0xFFA5B4FC),
    border: Color(0x4D6366F1),
  ),
  'Dietetics': TemplateSpecialtyColor(
    bg: Color(0x2684CC16),
    fg: Color(0xFFBEF264),
    border: Color(0x4D84CC16),
  ),
  'Administrative': _slate,
  'Custom': TemplateSpecialtyColor(
    bg: Color(0x2610B981),
    fg: AppColors.emerald400,
    border: Color(0x4D10B981),
  ),
};

TemplateSpecialtyColor specialtyColor(String specialty) =>
    kSpecialtyColors[specialty] ?? _slate;

/// All specialties present in the default library, in the order they first appear.
List<String> get kAllSpecialties {
  final out = <String>[];
  for (final t in kDefaultTemplates) {
    if (!out.contains(t.specialty)) out.add(t.specialty);
  }
  return out;
}

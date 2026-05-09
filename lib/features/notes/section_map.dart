/// Maps a template section name (the user-facing label, e.g. "Chief Complaint")
/// onto the NoteContent field key (e.g. "chiefComplaint").
///
/// 1:1 port of the sectionKeyMap object in
/// frontend/src/pages/NoteEditorPage.tsx:216-312. Whenever the web adds a new
/// template that introduces a new section name, mirror the entry here.
const Map<String, String> kSectionKeyMap = {
  // Core SOAP
  'Subjective': 'subjective',
  'Objective': 'objective',
  'Assessment': 'assessment',
  'Plan': 'plan',
  'Patient Instructions': 'instructions',
  'Instructions': 'instructions',

  // General / multi-specialty
  'Chief Complaint': 'chiefComplaint',
  'History of Present Illness': 'historyOfPresentIllness',
  'History': 'historyOfPresentIllness',
  'Review of Systems': 'reviewOfSystems',
  'Physical Exam': 'physicalExam',
  'Physical Examination Findings': 'physicalExam',
  'Assessment & Plan': 'plan',
  'Follow-Up': 'followUp',
  'Follow-Up Schedule': 'followUp',

  // Progress Notes
  'Letter to Patient': 'instructions',

  // Daily Note
  'Patient Identification': 'chiefComplaint',
  'Medical History': 'historyOfPresentIllness',
  'Current Medications': 'reviewOfSystems',

  // HPI
  'Identifying Information': 'chiefComplaint',
  'Past Medical History': 'historyOfPresentIllness',

  // Chart Notes
  'Date & Provider': 'chiefComplaint',
  'Clinical Findings': 'objective',

  // Chronic Care / Wellness
  'Patient Information': 'chiefComplaint',
  'Care Plan': 'plan',
  'Medications': 'reviewOfSystems',
  'Goals & Education': 'instructions',
  'Health Goals': 'chiefComplaint',
  'Lifestyle Assessment': 'subjective',
  'Nutrition': 'objective',
  'Physical Activity': 'assessment',
  'Mental Wellbeing': 'reviewOfSystems',

  // Psychiatry
  'Mental Status Exam': 'physicalExam',
  'Mental Status': 'physicalExam',
  'Safety Assessment': 'medicalDecisionMaking',
  'Presenting Problem': 'chiefComplaint',
  'Diagnosis': 'assessment',
  'Risk Factors': 'medicalDecisionMaking',
  'Social History': 'reviewOfSystems',

  // Mental Health
  'Client Identification': 'chiefComplaint',
  'Session Narrative': 'subjective',
  'Clinical Observations': 'objective',
  'Progress Evaluation': 'assessment',
  'Plan of Action': 'plan',
  'Demographics': 'chiefComplaint',
  'Presenting Concerns': 'subjective',
  'Psychiatric History': 'historyOfPresentIllness',
  'Substance Use History': 'reviewOfSystems',
  'Family History': 'reviewOfSystems',
  'Diagnosis & Treatment Plan': 'plan',

  // Therapy
  'Session Summary': 'subjective',
  'Interventions': 'assessment',
  'Client Response': 'objective',
  'Client Presentation': 'subjective',
  'Progress': 'assessment',

  // Pediatrics
  'Growth & Development': 'objective',
  'Developmental History': 'historyOfPresentIllness',

  // Cardiology
  'Cardiac History': 'historyOfPresentIllness',
  'ECG/Imaging': 'objective',
  'Diagnostic Findings': 'objective',

  // Dermatology
  'Skin Exam': 'physicalExam',
  'Lesion Description': 'objective',
  'Distribution': 'physicalExam',
  'Associated Symptoms': 'reviewOfSystems',

  // Orthopedics
  'Mechanism of Injury': 'historyOfPresentIllness',
  'Imaging': 'objective',
  'Imaging Findings': 'objective',
  'Injury Mechanism': 'historyOfPresentIllness',
};

/// Get the field key for a section label. Falls back to the section name
/// itself (so the web's "promote unknown to customSections" path works).
String sectionKeyFor(String section) =>
    kSectionKeyMap[section] ?? section;

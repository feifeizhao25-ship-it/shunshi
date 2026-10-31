// Text of the personalised block, English (international apps only). The domestic apps do not contain this file.
import 'personal_home_section.dart';

String _minutes(int n) => '$n min';
String _days(int n) => '$n days in a row';

const PersonalHomeStrings kPersonalHomeStringsEn = PersonalHomeStrings(
  heading: 'Picked for you today',
  why: 'Why you see this',
  turnOff: 'Turn off personalisation',
  turnOn: 'Turn on',
  offTitle: 'Personalisation is off',
  offBody: 'You are seeing general content. Your records are not deleted.',
  confirmTitle: 'Turn off personalised suggestions?',
  confirmBody: 'The home page will show general content only. Nothing is deleted and you can turn it back on any time.',
  cancel: 'Cancel',
  confirm: 'Turn off',
  errorTitle: 'Could not load right now',
  errorBody: 'Check your connection and try again.',
  retry: 'Try again',
  emptyTitle: 'No new suggestions for today',
  emptyBody: 'Check back a little later.',
  saveFailed: 'Could not save your setting. Please try again.',
  loading: 'Loading',
  letterSpacing: 0.4,
  minutes: _minutes,
  days: _days,
);

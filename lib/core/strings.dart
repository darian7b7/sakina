// German and English interface texts. Ayah translations come from assets/ayat.json, not from here.

const appName = 'Sakina';

const _texts = <String, Map<String, String>>{
  'de': {
    'nav.today': 'Heute',
    'nav.categories': 'Kategorien',
    'nav.saved': 'Gespeichert',
    'reference': 'Sure {s}, Vers {a}',
    'next': 'Weiter',
    'previous': 'Zurück',
    'save': 'Speichern',
    'unsave': 'Entfernen',
    'share': 'Teilen',
    'undo': 'Rückgängig',
    'removed': 'Entfernt',
    'empty.content': 'Noch keine Verse vorhanden.\nTrage sie in assets/ayat.json ein.',
    'empty.selection': 'Wähle mindestens eine Kategorie, um Verse zu sehen.',
    'empty.saved': 'Noch nichts gespeichert.\nTippe bei einem Vers auf das Lesezeichen.',
    'chooseCategories': 'Kategorien wählen',
    'categories.hint': 'Erinnerungen kommen aus allen gewählten Kategorien.',
    'categories.count': '{n} Verse',
    'nextReminder': 'Nächste Erinnerung: {when}',
    'remindersOff': 'Erinnerungen sind aus',
    'today': 'heute',
    'tomorrow': 'morgen',
    'settings': 'Einstellungen',
    'reminders': 'Erinnerungen',
    'reminders.on': 'Erinnerungen senden',
    'reminders.times': 'Uhrzeiten',
    'reminders.addTime': 'Uhrzeit',
    'reminders.days': 'Tage',
    'reminders.upcoming': 'Als Nächstes',
    'reminders.none': 'Keine Erinnerungen geplant.',
    'reminders.test': 'Test-Benachrichtigung senden',
    'reminders.denied': 'Benachrichtigungen sind nicht erlaubt. Bitte in den Systemeinstellungen freigeben.',
    'reminders.web': 'Im Browser werden geplante Erinnerungen nicht zugestellt, nur auf dem Handy. Die Test-Benachrichtigung funktioniert.',
    'display': 'Darstellung',
    'language': 'Sprache',
    'theme': 'Design',
    'theme.system': 'System',
    'theme.light': 'Hell',
    'theme.dark': 'Dunkel',
    'arabicSize': 'Schriftgröße Arabisch',
    'about': 'Inhalte',
    'about.text': 'Alle Verse und Übersetzungen stammen aus assets/ayat.json. Verwende nur geprüfte Quellen.',
    'error.content': 'Die Datei assets/ayat.json enthält einen Fehler:',
  },
  'en': {
    'nav.today': 'Today',
    'nav.categories': 'Categories',
    'nav.saved': 'Saved',
    'reference': 'Surah {s}, Ayah {a}',
    'next': 'Next',
    'previous': 'Previous',
    'save': 'Save',
    'unsave': 'Remove',
    'share': 'Share',
    'undo': 'Undo',
    'removed': 'Removed',
    'empty.content': 'No verses yet.\nAdd them to assets/ayat.json.',
    'empty.selection': 'Choose at least one category to see verses.',
    'empty.saved': 'Nothing saved yet.\nTap the bookmark on a verse.',
    'chooseCategories': 'Choose categories',
    'categories.hint': 'Reminders come from all selected categories.',
    'categories.count': '{n} verses',
    'nextReminder': 'Next reminder: {when}',
    'remindersOff': 'Reminders are off',
    'today': 'today',
    'tomorrow': 'tomorrow',
    'settings': 'Settings',
    'reminders': 'Reminders',
    'reminders.on': 'Send reminders',
    'reminders.times': 'Times',
    'reminders.addTime': 'Time',
    'reminders.days': 'Days',
    'reminders.upcoming': 'Coming up',
    'reminders.none': 'No reminders planned.',
    'reminders.test': 'Send test notification',
    'reminders.denied': 'Notifications are not allowed. Please enable them in the system settings.',
    'reminders.web': 'In the browser, scheduled reminders are not delivered, only on the phone. The test notification works.',
    'display': 'Display',
    'language': 'Language',
    'theme': 'Theme',
    'theme.system': 'System',
    'theme.light': 'Light',
    'theme.dark': 'Dark',
    'arabicSize': 'Arabic text size',
    'about': 'Content',
    'about.text': 'All verses and translations come from assets/ayat.json. Only use verified sources.',
    'error.content': 'The file assets/ayat.json contains an error:',
  },
};

const languages = {'de': 'Deutsch', 'en': 'English'};

/// Interface text for [key] in [lang], with {placeholders} filled from [vars].
String tr(String lang, String key, [Map<String, Object> vars = const {}]) {
  var s = _texts[lang]?[key] ?? _texts['en']![key] ?? key;
  vars.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Short weekday names, Monday first (DateTime.monday == 1).
List<String> weekdayNames(String lang) =>
    lang == 'de' ? ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'] : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

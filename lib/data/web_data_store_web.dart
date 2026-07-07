import 'dart:html' as html;

const _storageKey = 'mini_project_school_data';

String? readWebData() => html.window.localStorage[_storageKey];

void writeWebData(String value) {
  html.window.localStorage[_storageKey] = value;
}

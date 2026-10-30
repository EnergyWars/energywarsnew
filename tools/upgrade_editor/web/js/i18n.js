const FALLBACK = "en";
const dictionaries = {};
let language = FALLBACK;

export async function load(preferred) {
  for (const code of ["de", "en"]) {
    dictionaries[code] = await (await fetch(`i18n/${code}.json`)).json();
  }
  language = preferred && dictionaries[preferred] ? preferred : (navigator.language || "").startsWith("de") ? "de" : FALLBACK;
}

export function setLanguage(code) {
  language = dictionaries[code] ? code : FALLBACK;
}

export function current() {
  return language;
}

export function translate(dictionary, lang, key, params = {}) {
  const text = dictionary[lang]?.[key] ?? dictionary[FALLBACK]?.[key] ?? key;
  return text.replace(/\{(\w+)\}/g, (_, name) => String(params[name] ?? `{${name}}`));
}

export function t(key, params) {
  return translate(dictionaries, language, key, params);
}

export function gameName(names, key, fallback) {
  return names[key]?.[language] ?? names[key]?.[FALLBACK] ?? fallback;
}

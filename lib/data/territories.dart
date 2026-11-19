import '../models/country.dart';
import '../models/list_entry.dart';

const _eu = Continent.europe;
const _as = Continent.asia;
const _af = Continent.africa;
const _na = Continent.northAmerica;
const _sa = Continent.southAmerica;
const _oc = Continent.oceania;

/// Dependent and autonomous territories (ISO 3166-1), nested under the
/// country they belong to.
const List<TerritorySpec> territorySpecs = [
  // United Kingdom: overseas territories and crown dependencies.
  TerritorySpec('BM', 'Bermuda', 'GB', _na),
  TerritorySpec('GI', 'Gibraltar', 'GB', _eu),
  TerritorySpec('FK', 'Falkland Islands', 'GB', _sa),
  TerritorySpec('KY', 'Cayman Islands', 'GB', _na),
  TerritorySpec('VG', 'British Virgin Islands', 'GB', _na),
  TerritorySpec('MS', 'Montserrat', 'GB', _na),
  TerritorySpec('AI', 'Anguilla', 'GB', _na),
  TerritorySpec('TC', 'Turks and Caicos Islands', 'GB', _na),
  TerritorySpec('PN', 'Pitcairn Islands', 'GB', _oc),
  TerritorySpec(
    'SH',
    'Saint Helena, Ascension and Tristan da Cunha',
    'GB',
    _af,
  ),
  TerritorySpec('IO', 'British Indian Ocean Territory', 'GB', _as),
  TerritorySpec('GS', 'South Georgia and South Sandwich Islands', 'GB', _sa),
  TerritorySpec('GG', 'Guernsey', 'GB', _eu),
  TerritorySpec('JE', 'Jersey', 'GB', _eu),
  TerritorySpec('IM', 'Isle of Man', 'GB', _eu),
  // Constituent countries (user-assigned codes, not ISO 3166-1).
  TerritorySpec('XEN', 'England', 'GB', _eu, paintsWithParent: true),
  TerritorySpec('XSC', 'Scotland', 'GB', _eu, paintsWithParent: true),
  TerritorySpec('XWA', 'Wales', 'GB', _eu, paintsWithParent: true),
  TerritorySpec('XNI', 'Northern Ireland', 'GB', _eu, paintsWithParent: true),
  // France.
  TerritorySpec('GP', 'Guadeloupe', 'FR', _na),
  TerritorySpec('MQ', 'Martinique', 'FR', _na),
  TerritorySpec('GF', 'French Guiana', 'FR', _sa),
  TerritorySpec('RE', 'Réunion', 'FR', _af),
  TerritorySpec('YT', 'Mayotte', 'FR', _af),
  TerritorySpec('NC', 'New Caledonia', 'FR', _oc),
  TerritorySpec('PF', 'French Polynesia', 'FR', _oc),
  TerritorySpec('BL', 'Saint Barthélemy', 'FR', _na),
  TerritorySpec('MF', 'Saint Martin', 'FR', _na),
  TerritorySpec('PM', 'Saint Pierre and Miquelon', 'FR', _na),
  TerritorySpec('WF', 'Wallis and Futuna', 'FR', _oc),
  TerritorySpec('TF', 'French Southern and Antarctic Lands', 'FR', _af),
  // United States.
  TerritorySpec('PR', 'Puerto Rico', 'US', _na),
  TerritorySpec('GU', 'Guam', 'US', _oc),
  TerritorySpec('AS', 'American Samoa', 'US', _oc),
  TerritorySpec('VI', 'U.S. Virgin Islands', 'US', _na),
  TerritorySpec('MP', 'Northern Mariana Islands', 'US', _oc),
  TerritorySpec('UM', 'U.S. Minor Outlying Islands', 'US', _oc),
  // China.
  TerritorySpec('HK', 'Hong Kong', 'CN', _as),
  TerritorySpec('MO', 'Macau', 'CN', _as),
  // Netherlands.
  TerritorySpec('AW', 'Aruba', 'NL', _na),
  TerritorySpec('CW', 'Curaçao', 'NL', _na),
  TerritorySpec('SX', 'Sint Maarten', 'NL', _na),
  TerritorySpec('BQ', 'Caribbean Netherlands', 'NL', _na),
  // Denmark.
  TerritorySpec('GL', 'Greenland', 'DK', _na),
  TerritorySpec('FO', 'Faroe Islands', 'DK', _eu),
  // Australia.
  TerritorySpec('CX', 'Christmas Island', 'AU', _as),
  TerritorySpec('CC', 'Cocos (Keeling) Islands', 'AU', _as),
  TerritorySpec('NF', 'Norfolk Island', 'AU', _oc),
  TerritorySpec('HM', 'Heard Island and McDonald Islands', 'AU', _oc),
  // Norway.
  TerritorySpec('SJ', 'Svalbard and Jan Mayen', 'NO', _eu),
  TerritorySpec('BV', 'Bouvet Island', 'NO', _af),
  // New Zealand.
  TerritorySpec('TK', 'Tokelau', 'NZ', _oc),
  // Portugal (autonomous regions; user-assigned codes, not ISO 3166-1).
  TerritorySpec('XAZ', 'Azores', 'PT', _eu),
  TerritorySpec('XMD', 'Madeira', 'PT', _af),
  // Tanzania.
  TerritorySpec('XZA', 'Zanzibar', 'TZ', _af),
  // Somalia: breakaway state, shown nested but still marked DISP. The user can
  // instead treat it as an independent state (Profile tab).
  TerritorySpec(
    'XSL',
    'Somaliland',
    'SO',
    _af,
    status: EntryStatus.disputed,
    alignable: true,
  ),
  // Cyprus: breakaway state, same alignment choice as Somaliland.
  TerritorySpec(
    'XNC',
    'Northern Cyprus',
    'CY',
    _as,
    status: EntryStatus.disputed,
    alignable: true,
  ),
  // Finland.
  TerritorySpec('AX', 'Åland Islands', 'FI', _eu),
];

/// Non-member and disputed states without map geometry. Codes starting with
/// X are user-assigned (not ISO 3166-1).
const List<ExtraCountrySpec> extraCountrySpecs = [
  ExtraCountrySpec('CK', 'Cook Islands', EntryStatus.nonMember, _oc),
  ExtraCountrySpec('NU', 'Niue', EntryStatus.nonMember, _oc),
  ExtraCountrySpec('XK', 'Kosovo', EntryStatus.disputed, _eu),
  ExtraCountrySpec('XAB', 'Abkhazia', EntryStatus.disputed, _as),
  ExtraCountrySpec('XSO', 'South Ossetia', EntryStatus.disputed, _as),
  ExtraCountrySpec('XTR', 'Transnistria', EntryStatus.disputed, _eu),
];

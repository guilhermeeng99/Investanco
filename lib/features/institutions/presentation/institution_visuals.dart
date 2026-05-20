import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';

/// Brand glyph per institution kind, used in avatars and pickers.
FaIconData institutionKindIcon(InstitutionKind kind) => switch (kind) {
      InstitutionKind.bank => FontAwesomeIcons.buildingColumns,
      InstitutionKind.broker => FontAwesomeIcons.chartLine,
      InstitutionKind.internationalBroker => FontAwesomeIcons.globe,
      InstitutionKind.crypto => FontAwesomeIcons.bitcoin,
      InstitutionKind.other => FontAwesomeIcons.building,
    };

/// Stable accent colour per institution kind.
Color institutionKindColor(InstitutionKind kind) => switch (kind) {
      InstitutionKind.bank => const Color(0xFF1565C0),
      InstitutionKind.broker => const Color(0xFF00838F),
      InstitutionKind.internationalBroker => const Color(0xFF4527A0),
      InstitutionKind.crypto => const Color(0xFFEF6C00),
      InstitutionKind.other => const Color(0xFF546E7A),
    };

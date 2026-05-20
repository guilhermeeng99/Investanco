import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Localized label for an [InstitutionKind].
String institutionKindLabel(InstitutionKind kind) => switch (kind) {
      InstitutionKind.bank => t.institutions.kinds.bank,
      InstitutionKind.broker => t.institutions.kinds.broker,
      InstitutionKind.internationalBroker =>
        t.institutions.kinds.internationalBroker,
      InstitutionKind.crypto => t.institutions.kinds.crypto,
      InstitutionKind.other => t.institutions.kinds.other,
    };

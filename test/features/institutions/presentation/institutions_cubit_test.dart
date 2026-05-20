import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/institution_factory.dart';

class _MockInstitutionRepository extends Mock implements InstitutionRepository {}

class _FixedIdGenerator implements IdGenerator {
  @override
  String newId() => 'generated-id';
}

void main() {
  late _MockInstitutionRepository repository;
  final sample = institutionFactory();

  setUpAll(() {
    registerFallbackValue(sample);
  });

  setUp(() {
    repository = _MockInstitutionRepository();
    when(repository.watchAll).thenAnswer((_) => Stream.value([sample]));
  });

  blocTest<InstitutionsCubit, InstitutionsState>(
    'emits Loaded from the repository stream',
    build: () => InstitutionsCubit(repository, _FixedIdGenerator()),
    expect: () => [
      InstitutionsLoaded([sample]),
    ],
  );

  blocTest<InstitutionsCubit, InstitutionsState>(
    'add() persists a new institution via the repository',
    build: () => InstitutionsCubit(repository, _FixedIdGenerator()),
    setUp: () => when(() => repository.save(any()))
        .thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.add(
      name: 'XP',
      kind: InstitutionKind.broker,
      currency: Currency.brl,
    ),
    verify: (_) {
      final captured =
          verify(() => repository.save(captureAny())).captured.single;
      expect((captured as Institution).id, 'generated-id');
      expect(captured.name, 'XP');
    },
  );

  blocTest<InstitutionsCubit, InstitutionsState>(
    'remove() surfaces InUseFailure from the repository',
    build: () => InstitutionsCubit(repository, _FixedIdGenerator()),
    setUp: () => when(() => repository.delete(any()))
        .thenAnswer((_) async => const Left(InUseFailure())),
    act: (cubit) async {
      final failure = await cubit.remove('i1');
      expect(failure, isA<InUseFailure>());
    },
  );
}

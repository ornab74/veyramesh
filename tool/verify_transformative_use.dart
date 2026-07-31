// SPDX-License-Identifier: GPL-3.0-only

import 'dart:io';

const Set<String> forbiddenReferenceExtensions = <String>{
  '.dart', '.js', '.ts', '.tsx', '.jsx', '.py', '.rs', '.go', '.java', '.kt',
  '.c', '.cc', '.cpp', '.h', '.hpp', '.swift', '.cs', '.php', '.rb', '.sh',
};

void main() {
  final Directory root = Directory.current;
  final List<String> failures = <String>[];
  final Directory references = Directory('${root.path}/references');
  if (references.existsSync()) {
    for (final FileSystemEntity entity in references.listSync()) {
      if (entity is! Directory) continue;
      final File manifest = File('${entity.path}/claim.yaml');
      if (!manifest.existsSync()) {
        failures.add('${entity.path}: missing claim.yaml');
      } else {
        final String text = manifest.readAsStringSync();
        for (final String field in <String>[
          'claim_id:', 'owner:', 'source:', 'lawful_access_basis:', 'purpose:',
          'portion_used:', 'transformative_output:', 'market_substitution_risk:',
          'jurisdiction_assumed:', 'included_in_build:', 'replacement_status:',
          'reviewed_by:',
        ]) {
          if (!text.contains(field)) failures.add('${manifest.path}: missing $field');
        }
        if (!text.contains('included_in_build: false')) {
          failures.add('${manifest.path}: included_in_build must be false');
        }
      }
      for (final FileSystemEntity child in entity.listSync(recursive: true)) {
        if (child is! File) continue;
        final String lower = child.path.toLowerCase();
        if (forbiddenReferenceExtensions.any(lower.endsWith)) {
          failures.add('${child.path}: executable source is forbidden in references');
        }
      }
    }
  }

  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final String normalized = entity.path.replaceAll('\\', '/');
    if (normalized.contains('/.dart_tool/') || normalized.contains('/build/')) continue;
    final String text = entity.readAsStringSync();
    if (!text.startsWith('// SPDX-License-Identifier: GPL-3.0-only')) {
      failures.add('${entity.path}: missing GPL SPDX header');
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Transformative-use verification failed:');
    for (final String failure in failures) stderr.writeln(' - $failure');
    exitCode = 1;
    return;
  }
  stdout.writeln('Transformative-use verification passed.');
}

// SPDX-License-Identifier: GPL-3.0-only

/// Describes a quarantined reference used for research or commentary.
///
/// This data model records contributor reasoning; it does not make a legal
/// determination and must not be presented as one.
final class ReferenceClaim {
  const ReferenceClaim({
    required this.claimId,
    required this.owner,
    required this.source,
    required this.lawfulAccessBasis,
    required this.purpose,
    required this.portionUsed,
    required this.transformativeOutput,
    required this.marketSubstitutionRisk,
    required this.jurisdictionAssumed,
    required this.includedInBuild,
    required this.replacementStatus,
    required this.reviewedBy,
  });

  final String claimId;
  final String owner;
  final Uri source;
  final String lawfulAccessBasis;
  final String purpose;
  final String portionUsed;
  final String transformativeOutput;
  final String marketSubstitutionRisk;
  final String jurisdictionAssumed;
  final bool includedInBuild;
  final String replacementStatus;
  final String reviewedBy;

  List<String> validate() {
    final List<String> issues = <String>[];
    if (claimId.trim().isEmpty) issues.add('claim_id is required');
    if (!source.hasScheme) issues.add('source must be an absolute URI');
    if (purpose.trim().isEmpty) issues.add('purpose is required');
    if (portionUsed.trim().isEmpty) issues.add('portion_used is required');
    if (transformativeOutput.trim().isEmpty) {
      issues.add('transformative_output is required');
    }
    if (includedInBuild) {
      issues.add('quarantined reference material cannot be included in builds');
    }
    return issues;
  }
}

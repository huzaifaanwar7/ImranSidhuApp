import 'enums.dart';

class Sponsor {
  final String id;
  final String name;
  final String? tagline;
  final String? logoUrl;
  final String? websiteUrl;
  final String? contactPhone;
  final List<SponsorSlot> slots;
  final bool isActive;

  const Sponsor({
    required this.id,
    required this.name,
    this.tagline,
    this.logoUrl,
    this.websiteUrl,
    this.contactPhone,
    this.slots = const [],
    this.isActive = true,
  });
}

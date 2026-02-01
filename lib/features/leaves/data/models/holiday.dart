
class Holiday {
  final String id;
  final String name;
  final DateTime date;
  final bool isPublic;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
    this.isPublic = true,
  });
}

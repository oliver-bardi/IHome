class Status {
  final String status;

  Status({required this.status});

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      status: json['status'],
    );
  }
}

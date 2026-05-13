class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  final bool success;
  final String message;
  final T data;
  final dynamic meta;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data) parser,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: parser(json['data']),
      meta: json['meta'],
    );
  }
}

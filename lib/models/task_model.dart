class AttachmentModel {
  final String filename;
  final String url;
  final String? mimeType;
  final String? uploadedBy;
  final DateTime? uploadedAt;

  AttachmentModel({
    required this.filename,
    required this.url,
    this.mimeType,
    this.uploadedBy,
    this.uploadedAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      mimeType: json['mimeType'],
      uploadedBy: json['uploadedBy'],
      uploadedAt: json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      if (mimeType != null) 'mimeType': mimeType,
      if (uploadedBy != null) 'uploadedBy': uploadedBy,
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
    };
  }
}

class CommentModel {
  final String? id;
  final String author;
  final String authorName;
  final String text;
  final DateTime createdAt;

  CommentModel({
    this.id,
    required this.author,
    this.authorName = '',
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'],
      author: json['author'] is String
          ? json['author']
          : json['author']?['_id'] ?? json['author']?['id'] ?? '',
      authorName: json['author'] is Map
          ? json['author']['name'] ?? ''
          : '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'author': author,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TimeLogModel {
  final String? id;
  final String userId;
  final String userName;
  final double hours;
  final DateTime date;
  final bool billable;
  final String? note;

  TimeLogModel({
    this.id,
    required this.userId,
    this.userName = '',
    required this.hours,
    required this.date,
    this.billable = true,
    this.note,
  });

  factory TimeLogModel.fromJson(Map<String, dynamic> json) {
    return TimeLogModel(
      id: json['_id'],
      userId: json['user'] is String
          ? json['user']
          : json['user']?['_id'] ?? json['user']?['id'] ?? '',
      userName: json['user'] is Map
          ? json['user']['name'] ?? ''
          : '',
      hours: (json['hours'] ?? 0).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      billable: json['billable'] ?? true,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'user': userId,
      'hours': hours,
      'date': date.toIso8601String(),
      'billable': billable,
      if (note != null) 'note': note,
    };
  }
}

class TaskAssigneeModel {
  final String id;
  final String name;
  final String email;

  TaskAssigneeModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TaskAssigneeModel.fromJson(Map<String, dynamic> json) {
    return TaskAssigneeModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class TaskModel {
  final String id;
  final String project;
  final String title;
  final String? description;
  final List<TaskAssigneeModel> assignees;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String state; // 'new', 'in_progress', 'blocked', 'done'
  final double estimateHours;
  final List<TimeLogModel> timeLogs;
  final List<CommentModel> comments;
  final List<AttachmentModel> attachments;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.project,
    required this.title,
    this.description,
    this.assignees = const [],
    this.dueDate,
    this.priority = 'medium',
    this.state = 'new',
    this.estimateHours = 0,
    this.timeLogs = const [],
    this.comments = const [],
    this.attachments = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] ?? json['id'] ?? '',
      project: json['project'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
              .where((a) => a is Map<String, dynamic>)
              .map((a) => TaskAssigneeModel.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'] ?? 'medium',
      state: json['state'] ?? 'new',
      estimateHours: (json['estimateHours'] ?? 0).toDouble(),
      timeLogs: json['timeLogs'] != null
          ? (json['timeLogs'] as List).map((t) => TimeLogModel.fromJson(t)).toList()
          : [],
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => CommentModel.fromJson(c)).toList()
          : [],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((a) => AttachmentModel.fromJson(a)).toList()
          : [],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project': project,
      'title': title,
      if (description != null) 'description': description,
      'assignees': assignees.map((a) => a.id).toList(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'priority': priority,
      'state': state,
      'estimateHours': estimateHours,
      'timeLogs': timeLogs.map((t) => t.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  TaskModel copyWith({
    String? id,
    String? project,
    String? title,
    String? description,
    List<TaskAssigneeModel>? assignees,
    DateTime? dueDate,
    String? priority,
    String? state,
    double? estimateHours,
    List<TimeLogModel>? timeLogs,
    List<CommentModel>? comments,
    List<AttachmentModel>? attachments,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      project: project ?? this.project,
      title: title ?? this.title,
      description: description ?? this.description,
      assignees: assignees ?? this.assignees,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      state: state ?? this.state,
      estimateHours: estimateHours ?? this.estimateHours,
      timeLogs: timeLogs ?? this.timeLogs,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalLoggedHours {
    return timeLogs.fold(0, (sum, log) => sum + log.hours);
  }

  bool get isOverEstimate => totalLoggedHours > estimateHours;

  bool get isOverdue {
    if (dueDate == null || state == 'done') return false;
    return DateTime.now().isAfter(dueDate!);
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    final difference = dueDate!.difference(DateTime.now());
    return difference.inDays;
  }
}

// Task Priority Constants
class TaskPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';

  static const List<String> allPriorities = [low, medium, high, urgent];

  static String getLabel(String priority) {
    switch (priority) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      case urgent:
        return 'Urgent';
      default:
        return priority;
    }
  }
}

// Task State Constants
class TaskState {
  static const String newTask = 'new';
  static const String inProgress = 'in_progress';
  static const String blocked = 'blocked';
  static const String done = 'done';

  static const List<String> allStates = [newTask, inProgress, blocked, done];

  static String getLabel(String state) {
    switch (state) {
      case newTask:
        return 'New';
      case inProgress:
        return 'In Progress';
      case blocked:
        return 'Blocked';
      case done:
        return 'Done';
      default:
        return state;
    }
  }
}

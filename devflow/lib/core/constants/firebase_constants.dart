/// Firestore collection and sub-collection names matching PRD
class FirebaseConstants {
  // Root collections
  static const String colUsers = 'users';
  static const String colWorkspaces = 'workspaces';

  // Sub-collections under workspaces/{workspaceId}/
  static const String subColFlowEntries = 'flow_entries';
  static const String subColCodeAnnotations = 'code_annotations';
  static const String subColProjectTodos = 'project_todos';
}

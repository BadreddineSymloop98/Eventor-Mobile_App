import '../../../core/base/base_view_model.dart';
import '../../../core/models/account.dart';

/// Drives the role selection screen.
///
/// It holds which role is selected and nothing else. The choice is not
/// persisted here: it belongs to the account being created, so it travels on
/// to the register form and is saved with the rest of the sign-up.
class RoleSelectionViewModel extends BaseViewModel {
  /// The roles offered, in the order the design lists them.
  static const List<UserRole> roles = UserRole.values;

  UserRole? _selectedRole;

  /// The role the user picked, or `null` while they have not picked one.
  ///
  /// Nothing is selected at first. The design shows a selected card, but that
  /// is the component's selected state on display rather than a default — the
  /// screen says the choice cannot be changed later, so pre-selecting one
  /// invites a mistake.
  UserRole? get selectedRole => _selectedRole;

  /// Whether the user may move on.
  bool get canContinue => _selectedRole != null;

  bool isSelected(UserRole role) => _selectedRole == role;

  /// Picks [role]. Selecting the one already selected is a no-op rather than
  /// a toggle — there is no valid "no role" state to go back to once the user
  /// has answered.
  void selectRole(UserRole role) {
    if (_selectedRole == role) return;

    _selectedRole = role;
    notifyListeners();
  }
}

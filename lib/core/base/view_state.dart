/// The lifecycle state a view model can be in.
///
/// Views map this to what they render: a loader, the content, or an error.
enum ViewState { idle, busy, error }

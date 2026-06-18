/// Lifecycle of a [WalkthroughActivity].
///
/// Never stored directly: [WalkthroughActivity.state] derives this from the
/// activity's answers and completion timestamp so the lifecycle cannot drift
/// out of sync with the underlying data.
enum WalkthroughState { notStarted, inProgress, completed }

/// Semantic-version style comparison (supports `-beta.1` pre-releases).
int compareVersions(String a, String b) {
  final pa = _Parsed.parse(a);
  final pb = _Parsed.parse(b);
  for (var i = 0; i < 3; i++) {
    final c = pa.core[i].compareTo(pb.core[i]);
    if (c != 0) return c;
  }
  if (pa.pre.isEmpty && pb.pre.isEmpty) return 0;
  if (pa.pre.isEmpty) return 1; // release > pre-release
  if (pb.pre.isEmpty) return -1;

  final n = pa.pre.length < pb.pre.length ? pa.pre.length : pb.pre.length;
  for (var i = 0; i < n; i++) {
    final x = pa.pre[i];
    final y = pb.pre[i];
    final nx = int.tryParse(x);
    final ny = int.tryParse(y);
    int c;
    if (nx != null && ny != null) {
      c = nx.compareTo(ny);
    } else if (nx != null) {
      c = -1;
    } else if (ny != null) {
      c = 1;
    } else {
      c = x.compareTo(y);
    }
    if (c != 0) return c;
  }
  return pa.pre.length.compareTo(pb.pre.length);
}

/// Whether [remote] is strictly newer than [local].
bool isNewerVersion(String remote, String local) =>
    compareVersions(remote, local) > 0;

class _Parsed {
  _Parsed(this.core, this.pre);
  final List<int> core;
  final List<String> pre;

  static _Parsed parse(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);
    final plus = v.indexOf('+');
    if (plus >= 0) v = v.substring(0, plus);
    final dash = v.indexOf('-');
    final corePart = dash >= 0 ? v.substring(0, dash) : v;
    final prePart = dash >= 0 ? v.substring(dash + 1) : '';
    final nums = corePart.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (nums.length < 3) {
      nums.add(0);
    }
    return _Parsed(nums, prePart.isEmpty ? <String>[] : prePart.split('.'));
  }
}

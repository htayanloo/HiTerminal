import 'package:flutter/widgets.dart';

sealed class SplitNode {
  final String id;
  const SplitNode({required this.id});
}

class SplitLeaf extends SplitNode {
  final String panelId;

  const SplitLeaf({
    required super.id,
    required this.panelId,
  });
}

class SplitBranch extends SplitNode {
  final Axis axis;
  final double ratio;
  final SplitNode first;
  final SplitNode second;

  const SplitBranch({
    required super.id,
    required this.axis,
    this.ratio = 0.5,
    required this.first,
    required this.second,
  });

  SplitBranch copyWith({
    Axis? axis,
    double? ratio,
    SplitNode? first,
    SplitNode? second,
  }) {
    return SplitBranch(
      id: id,
      axis: axis ?? this.axis,
      ratio: ratio ?? this.ratio,
      first: first ?? this.first,
      second: second ?? this.second,
    );
  }
}

// Tree manipulation helpers
class SplitTreeOps {
  static int _idCounter = 0;

  static String _nextId(String prefix) {
    _idCounter++;
    return '${prefix}_$_idCounter';
  }

  /// Split a leaf node into a branch with the original leaf and a new leaf
  static SplitNode splitLeaf(
    SplitNode tree,
    String leafId,
    Axis axis,
    String newPanelId,
  ) {
    return _replaceNode(tree, leafId, (leaf) {
      return SplitBranch(
        id: _nextId('branch'),
        axis: axis,
        first: leaf,
        second: SplitLeaf(
          id: _nextId('leaf'),
          panelId: newPanelId,
        ),
      );
    });
  }

  /// Split a leaf, placing an existing panel either first or second
  static SplitNode splitLeafWithExisting(
    SplitNode tree,
    String targetLeafId,
    Axis axis,
    String existingPanelId,
    bool existingFirst,
  ) {
    return _replaceNode(tree, targetLeafId, (leaf) {
      final newLeaf = SplitLeaf(
        id: _nextId('leaf'),
        panelId: existingPanelId,
      );
      return SplitBranch(
        id: _nextId('branch'),
        axis: axis,
        first: existingFirst ? newLeaf : leaf,
        second: existingFirst ? leaf : newLeaf,
      );
    });
  }

  /// Remove a leaf and promote its sibling
  static SplitNode? removeLeaf(SplitNode tree, String leafId) {
    if (tree is SplitLeaf) {
      return tree.id == leafId ? null : tree;
    }
    if (tree is SplitBranch) {
      // Check if one of the direct children is the target leaf
      if (tree.first is SplitLeaf && (tree.first as SplitLeaf).id == leafId) {
        return tree.second;
      }
      if (tree.second is SplitLeaf && (tree.second as SplitLeaf).id == leafId) {
        return tree.first;
      }
      // Recurse
      final newFirst = removeLeaf(tree.first, leafId);
      if (newFirst != tree.first) {
        return newFirst == null ? tree.second : tree.copyWith(first: newFirst);
      }
      final newSecond = removeLeaf(tree.second, leafId);
      if (newSecond != tree.second) {
        return newSecond == null ? tree.first : tree.copyWith(second: newSecond);
      }
    }
    return tree;
  }

  /// Update the ratio of a branch
  static SplitNode updateRatio(SplitNode tree, String branchId, double ratio) {
    if (tree is SplitBranch) {
      if (tree.id == branchId) {
        return tree.copyWith(ratio: ratio.clamp(0.1, 0.9));
      }
      final newFirst = updateRatio(tree.first, branchId, ratio);
      final newSecond = updateRatio(tree.second, branchId, ratio);
      if (newFirst != tree.first || newSecond != tree.second) {
        return tree.copyWith(first: newFirst, second: newSecond);
      }
    }
    return tree;
  }

  /// Collect all panel IDs from the tree
  static List<String> allPanelIds(SplitNode tree) {
    if (tree is SplitLeaf) return [tree.panelId];
    if (tree is SplitBranch) {
      return [...allPanelIds(tree.first), ...allPanelIds(tree.second)];
    }
    return [];
  }

  /// Collect all leaf node IDs
  static List<String> allLeafIds(SplitNode tree) {
    if (tree is SplitLeaf) return [tree.id];
    if (tree is SplitBranch) {
      return [...allLeafIds(tree.first), ...allLeafIds(tree.second)];
    }
    return [];
  }

  /// Find the leaf ID for a given panel ID
  static String? findLeafByPanelId(SplitNode tree, String panelId) {
    if (tree is SplitLeaf) {
      return tree.panelId == panelId ? tree.id : null;
    }
    if (tree is SplitBranch) {
      return findLeafByPanelId(tree.first, panelId) ??
          findLeafByPanelId(tree.second, panelId);
    }
    return null;
  }

  static SplitNode _replaceNode(
    SplitNode tree,
    String nodeId,
    SplitNode Function(SplitNode) replacer,
  ) {
    if (tree.id == nodeId) return replacer(tree);
    if (tree is SplitBranch) {
      final newFirst = _replaceNode(tree.first, nodeId, replacer);
      final newSecond = _replaceNode(tree.second, nodeId, replacer);
      if (newFirst != tree.first || newSecond != tree.second) {
        return tree.copyWith(first: newFirst, second: newSecond);
      }
    }
    return tree;
  }
}

import logging
from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Callable
import numpy as np
import slangpy as spy
from collections import deque

from cs248a_renderer.model.bounding_box import BoundingBox3D
from cs248a_renderer.model.primitive import Primitive
from tqdm import tqdm


logger = logging.getLogger(__name__)


@dataclass
class BVHNode:
    # The bounding box of this node.
    bound: BoundingBox3D = field(default_factory=BoundingBox3D)
    # The index of the left child node, or -1 if this is a leaf node.
    left: int = -1
    # The index of the right child node, or -1 if this is a leaf node.
    right: int = -1
    # The starting index of the primitives in the primitives array.
    prim_left: int = 0
    # The ending index (exclusive) of the primitives in the primitives array.
    prim_right: int = 0
    # The depth of this node in the BVH tree.
    depth: int = 0

    def get_this(self) -> Dict:
        return {
            "bound": self.bound.get_this(),
            "left": self.left,
            "right": self.right,
            "primLeft": self.prim_left,
            "primRight": self.prim_right,
            "depth": self.depth,
        }

    @property
    def is_leaf(self) -> bool:
        """Checks if this node is a leaf node."""
        return self.left == -1 and self.right == -1


def join_primitives(primitives: List[Primitive]) -> BoundingBox3D:
        joined: BoundingBox3D = primitives[0].bounding_box
        for p in primitives:
            joined = BoundingBox3D.union(joined, p.bounding_box)
        return joined

def join_bboxes(bboxes: List[BoundingBox3D]) -> BoundingBox3D:
        joined: BoundingBox3D = bboxes[0]
        for b in bboxes:
                joined = BoundingBox3D.union(joined, b)
        return joined

class BVH:
    def __init__(
        self,
        primitives: List[Primitive],
        max_nodes: int,
        min_prim_per_node: int = 1,
        num_thresholds: int = 16,
        on_progress: Callable[[int, int], None] | None = None,
    ) -> None:
        """
        Builds the BVH from the given list of primitives. The build algorithm should
        reorder the primitives in-place to align with the BVH node structure.
        The algorithm will start from the root node and recursively partition the primitives
        into child nodes until the maximum number of nodes is reached or the primitives
        cannot be further subdivided.
        At each node, the splitting axis and threshold should be chosen using the Surface Area Heuristic (SAH)
        to minimize the expected cost of traversing the BVH during ray intersection tests.

        :param primitives: the list of primitives to build the BVH from
        :type primitives: List[Primitive]
        :param max_nodes: the maximum number of nodes in the BVH
        :type max_nodes: int
        :param min_prim_per_node: the minimum number of primitives per leaf node
        :type min_prim_per_node: int
        :param num_thresholds: the number of thresholds per axis to consider when splitting
        :type num_thresholds: int
        """
        self.nodes: List[BVHNode] = []

        root = BVHNode(join_primitives(primitives), -1, -1, 0, len(primitives), 0)
        self.nodes.append(root)
        stk = deque()
        stk.append(0)

        # TODO: Student implementation starts here.
        while (len(stk) > 0 and len(self.nodes) < max_nodes):
            node_idx = stk.popleft()
            node = self.nodes[node_idx]

            if node.prim_right - node.prim_left <= min_prim_per_node:
                continue

            result = self.partition(node, primitives, min_prim_per_node, num_thresholds)
            if result is None:
                continue

            left_node, right_node = result

            node.left = len(self.nodes)
            self.nodes.append(left_node)

            node.right = len(self.nodes)
            self.nodes.append(right_node)

            stk.append(node.left)
            stk.append(node.right)

            if on_progress:
                on_progress(len(self.nodes), max_nodes)
            

        # TODO: Student implementation ends here.

    def partition(self, node: BVHNode, primitives: List[Primitive], min_prim_per_node: int, num_thresholds: int):
            """
            Partitions the primitives in the given node into left and right child nodes
            using the Surface Area Heuristic (SAH) to choose the best splitting axis and threshold.

            :param node: The BVH node to partition.
            :param primitives: The list of primitives to partition.
            :param min_prim_per_node: The minimum number of primitives per leaf node.
            :param num_thresholds: The number of thresholds per axis to consider when splitting.
            """
            parent_area = node.bound.area
            best_cost = float("inf")
            best_axis = "?"
            best_split = -1

            # leaf cost = intersect all primitives
            leaf_cost = node.prim_right - node.prim_left

            for axis in ("x", "y", "z"):
                # Build bins
                bins = [{"bbox": None, "count": 0} for _ in range(num_thresholds)]

                min_a = getattr(node.bound.min, axis)
                max_a = getattr(node.bound.max, axis)
                extent = max_a - min_a

                if extent <= 1e-6:
                    continue

                inv_extent = num_thresholds / extent

                for i in range(node.prim_left, node.prim_right):
                    c = getattr(primitives[i].bounding_box.center, axis)
                    idx = int((c - min_a) * inv_extent)
                    idx = max(0, min(num_thresholds - 1, idx))

                    if bins[idx]["bbox"] is None:
                        bins[idx]["bbox"] = primitives[i].bounding_box
                    else:
                        bins[idx]["bbox"] = BoundingBox3D.union(
                            bins[idx]["bbox"], primitives[i].bounding_box
                        )
                    bins[idx]["count"] += 1

                # Prefix/suffix sweep
                left_bbox = [None] * num_thresholds
                right_bbox = [None] * num_thresholds
                left_count = [0] * num_thresholds
                right_count = [0] * num_thresholds

                bbox = None
                count = 0
                for i in range(num_thresholds):
                    if bins[i]["bbox"] is not None:
                        bbox = bins[i]["bbox"] if bbox is None else BoundingBox3D.union(bbox, bins[i]["bbox"])
                        count += bins[i]["count"]
                    left_bbox[i] = bbox
                    left_count[i] = count

                bbox = None
                count = 0
                for i in reversed(range(num_thresholds)):
                    if bins[i]["bbox"] is not None:
                        bbox = bins[i]["bbox"] if bbox is None else BoundingBox3D.union(bbox, bins[i]["bbox"])
                        count += bins[i]["count"]
                    right_bbox[i] = bbox
                    right_count[i] = count

                

                # Evaluate splits
                for i in range(1, num_thresholds):
                    if left_count[i - 1] < min_prim_per_node:
                        continue
                    if right_count[i] < min_prim_per_node:
                        continue

                    cost = (
                        (left_bbox[i - 1].area / parent_area) * left_count[i - 1]
                        + (right_bbox[i].area / parent_area) * right_count[i]
                    )

                    if cost < best_cost:
                        best_cost = cost
                        best_axis = axis
                        best_split = i

            if best_axis is None or best_cost >= leaf_cost:
                ValueError("Cannot find a valid split.")
                return None

            # Reorder primitives in-place
            left_prims = []
            right_prims = []

            min_a = getattr(node.bound.min, best_axis)
            max_a = getattr(node.bound.max, best_axis)
            inv_extent = num_thresholds / (max_a - min_a)

            for i in range(node.prim_left, node.prim_right):
                c = getattr(primitives[i].bounding_box.center, best_axis)
                idx = int((c - min_a) * inv_extent)
                idx = max(0, min(num_thresholds - 1, idx))

                if idx < best_split:
                    left_prims.append(primitives[i])
                else:
                    right_prims.append(primitives[i])

            mid = node.prim_left + len(left_prims)
            primitives[node.prim_left : node.prim_right] = left_prims + right_prims

            left_bbox = join_primitives(left_prims)
            right_bbox = join_primitives(right_prims)

            left_node = BVHNode(left_bbox, -1, -1, node.prim_left, mid, node.depth+1)
            right_node = BVHNode(right_bbox, -1, -1, mid, node.prim_right, node.depth+1)

            return left_node, right_node


def create_bvh_node_buf(module: spy.Module, bvh_nodes: List[BVHNode]) -> spy.NDBuffer:
    device = module.device
    node_buf = spy.NDBuffer(
        device=device, dtype=module.BVHNode.as_struct(), shape=(max(len(bvh_nodes), 1),)
    )
    cursor = node_buf.cursor()
    for idx, node in enumerate(bvh_nodes):
        cursor[idx].write(node.get_this())
    cursor.apply()
    return node_buf

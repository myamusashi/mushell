#pragma once

// Compatibility shim for the vendored material-color-utilities: wsmeans.cc
// uses absl::flat_hash_map only as an Argb->int counter; upstream's own
// benchmark comment measures std::unordered_map ~2ms slower per 1000 runs,
// which is negligible at the 128px bitmap size used here.

#include <cstddef>
#include <functional>
#include <unordered_map>

namespace absl {

template <typename Key, typename Value, typename Hash = std::hash<Key>, typename Equal = std::equal_to<Key>>
using flat_hash_map = std::unordered_map<Key, Value, Hash, Equal>;

} // namespace absl

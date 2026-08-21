#pragma once

// Compatibility shim for the vendored material-color-utilities: covers the
// single absl::StrCat(absl::Hex(argb)) call in utils.cc (lowercase hex,
// zero-padded to nothing, matching absl::Hex defaults).

#include <cstdint>
#include <cstdio>
#include <string>

namespace absl {

struct Hex {
    char buffer[17];

    explicit Hex(std::uint64_t value) {
        std::snprintf(buffer, sizeof(buffer), "%llx", static_cast<unsigned long long>(value));
    }
};

inline std::string StrCat(const Hex& hex) {
    return std::string(hex.buffer);
}

} // namespace absl

#pragma once

#include <qlist.h>
#include <qmap.h>
#include <qstring.h>

// Direct ports of fix_surface_extremes() and validate_palette() from
// generate_colors_material.py. Thresholds must not be changed.

// Roles consumers resolve through Colours.qml — both modes must always
// contain these (REQUIRED_ROLES in the Python script).
const QList<QString>& requiredRoles();

// In-place fix of pure black/white surface roles using the neutral palette
// key color. Returns false when the neutral key color is missing/malformed.
bool fixSurfaceExtremes(QMap<QString, QString>& colors);

// Validates required roles, hex format, non-pure surface colors and fg/bg
// tone contrast. Returns false and fills error on failure.
bool validatePalette(const QMap<QString, QString>& colors, QString& error);

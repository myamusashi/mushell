#!/usr/bin/env bash

# Find all QML files and replace Theme.colors.* with Theme.m3Colors.* in camelCase

find . -name "*.qml" -type f -exec sed -i \
  -e 's/Themes\.colors\.error_container/Themes.m3Colors.errorContainer/g' \
  -e 's/Themes\.colors\.inverse_on_surface/Themes.m3Colors.inverseOnSurface/g' \
  -e 's/Themes\.colors\.inverse_primary/Themes.m3Colors.inversePrimary/g' \
  -e 's/Themes\.colors\.inverse_surface/Themes.m3Colors.inverseSurface/g' \
  -e 's/Themes\.colors\.on_background/Themes.m3Colors.onBackground/g' \
  -e 's/Themes\.colors\.on_error_container/Themes.m3Colors.onErrorContainer/g' \
  -e 's/Themes\.colors\.on_error/Themes.m3Colors.onError/g' \
  -e 's/Themes\.colors\.on_primary_container/Themes.m3Colors.onPrimaryContainer/g' \
  -e 's/Themes\.colors\.on_primary_fixed_variant/Themes.m3Colors.onPrimaryFixedVariant/g' \
  -e 's/Themes\.colors\.on_primary_fixed/Themes.m3Colors.onPrimaryFixed/g' \
  -e 's/Themes\.colors\.on_primary/Themes.m3Colors.onPrimary/g' \
  -e 's/Themes\.colors\.on_secondary_container/Themes.m3Colors.onSecondaryContainer/g' \
  -e 's/Themes\.colors\.on_secondary_fixed_variant/Themes.m3Colors.onSecondaryFixedVariant/g' \
  -e 's/Themes\.colors\.on_secondary_fixed/Themes.m3Colors.onSecondaryFixed/g' \
  -e 's/Themes\.colors\.on_secondary/Themes.m3Colors.onSecondary/g' \
  -e 's/Themes\.colors\.on_surface_variant/Themes.m3Colors.onSurfaceVariant/g' \
  -e 's/Themes\.colors\.on_surface/Themes.m3Colors.onSurface/g' \
  -e 's/Themes\.colors\.on_tertiary_container/Themes.m3Colors.onTertiaryContainer/g' \
  -e 's/Themes\.colors\.on_tertiary_fixed_variant/Themes.m3Colors.onTertiaryFixedVariant/g' \
  -e 's/Themes\.colors\.on_tertiary_fixed/Themes.m3Colors.onTertiaryFixed/g' \
  -e 's/Themes\.colors\.on_tertiary/Themes.m3Colors.onTertiary/g' \
  -e 's/Themes\.colors\.outline_variant/Themes.m3Colors.outlineVariant/g' \
  -e 's/Themes\.colors\.primary_container/Themes.m3Colors.primaryContainer/g' \
  -e 's/Themes\.colors\.primary_fixed_dim/Themes.m3Colors.primaryFixedDim/g' \
  -e 's/Themes\.colors\.primary_fixed/Themes.m3Colors.primaryFixed/g' \
  -e 's/Themes\.colors\.secondary_container/Themes.m3Colors.secondaryContainer/g' \
  -e 's/Themes\.colors\.secondary_fixed_dim/Themes.m3Colors.secondaryFixedDim/g' \
  -e 's/Themes\.colors\.secondary_fixed/Themes.m3Colors.secondaryFixed/g' \
  -e 's/Themes\.colors\.surface_bright/Themes.m3Colors.surfaceBright/g' \
  -e 's/Themes\.colors\.surface_container_highest/Themes.m3Colors.surfaceContainerHighest/g' \
  -e 's/Themes\.colors\.surface_container_high/Themes.m3Colors.surfaceContainerHigh/g' \
  -e 's/Themes\.colors\.surface_container_lowest/Themes.m3Colors.surfaceContainerLowest/g' \
  -e 's/Themes\.colors\.surface_container_low/Themes.m3Colors.surfaceContainerLow/g' \
  -e 's/Themes\.colors\.surface_container/Themes.m3Colors.surfaceContainer/g' \
  -e 's/Themes\.colors\.surface_dim/Themes.m3Colors.surfaceDim/g' \
  -e 's/Themes\.colors\.surface_tint/Themes.m3Colors.surfaceTint/g' \
  -e 's/Themes\.colors\.surface_variant/Themes.m3Colors.surfaceVariant/g' \
  -e 's/Themes\.colors\.tertiary_container/Themes.m3Colors.tertiaryContainer/g' \
  -e 's/Themes\.colors\.tertiary_fixed_dim/Themes.m3Colors.tertiaryFixedDim/g' \
  -e 's/Themes\.colors\.tertiary_fixed/Themes.m3Colors.tertiaryFixed/g' \
  -e 's/Themes\.colors\.background/Themes.m3Colors.background/g' \
  -e 's/Themes\.colors\.error/Themes.m3Colors.error/g' \
  -e 's/Themes\.colors\.outline/Themes.m3Colors.outline/g' \
  -e 's/Themes\.colors\.primary/Themes.m3Colors.primary/g' \
  -e 's/Themes\.colors\.scrim/Themes.m3Colors.scrim/g' \
  -e 's/Themes\.colors\.secondary/Themes.m3Colors.secondary/g' \
  -e 's/Themes\.colors\.shadow/Themes.m3Colors.shadow/g' \
  -e 's/Themes\.colors\.surface/Themes.m3Colors.surface/g' \
  -e 's/Themes\.colors\.tertiary/Themes.m3Colors.tertiary/g' \
  {} +

echo "Conversion complete!"

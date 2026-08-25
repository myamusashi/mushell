# Shared single-worker executor. Plain static library on purpose: no QML
# types are exported, every module that offloads work just links vast-jobs.
qt_add_library(vast-jobs STATIC
    JobExecutor.hpp
    JobExecutor.cpp
)

target_link_libraries(vast-jobs PUBLIC Qt::Core)
